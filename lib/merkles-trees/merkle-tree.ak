use aiken/hash.{Hash, blake2b_256, Blake2b_256}
use aiken/list
use aiken/bytearray

type MerkleTree {
    Node(Hash<Blake2b_256, ByteArray>, MerkleTree, MerkleTree)
    Leaf(Hash<Blake2b_256, ByteArray>,ByteArray)
}

fn merge_branches(set: List<MerkleTree>) -> List<MerkleTree> {
    when set is {
        [Leaf(hash_a,..) as a, Leaf(hash_b,..) as b,..] -> {
            let new_hash = blake2b_256(bytearray.concat(hash_a,hash_b))
            let create_node = Node(new_hash,a,b)
            list.concat([create_node],merge_branches(list.drop(set,2)))
        }
        [Node(hash_a,..) as a, Node(hash_b,..) as b,..] -> {
            let new_hash = blake2b_256(bytearray.concat(hash_a,hash_b))
            let create_node = Node(new_hash,a,b)
            list.concat([create_node],merge_branches(list.drop(set,2)))
        }
        [Leaf(hash_a,..) as a] -> {
            let new_hash = blake2b_256(hash_a)
            let create_node = Node(new_hash,a,Leaf(#"",#""))
            list.concat([create_node],merge_branches(list.drop(set,2)))
        }
        _ -> {
            []
        }
    }
}

fn compose_merkle_tree(set: List<MerkleTree>) -> List<MerkleTree> {
     if list.length(set) == 1 {
        set
    } else {
        let new_set = merge_branches(set)
        compose_merkle_tree(new_set)
    }
}

fn to_leaf(set: List<ByteArray>) -> List<MerkleTree> {
    list.map(set, fn (x) {
        if x == #"" {
           Leaf(blake2b_256(x),#"")
        } else {
            Leaf(blake2b_256(x),x)
        }
    })
}

fn create_merkle_tree(set: List<ByteArray>) -> MerkleTree {
   expect [result] = to_leaf(set) |> compose_merkle_tree()
   result
}


test mt_creation_1 () {
    let mkt_1 = Node(#"d307075d4a2c34a02d4c48a4bf26ccc38636f36d8143d219b7c9dcccdfdea43b",Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"), Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"))
    let mkt_2 = create_merkle_tree([#"1234",#"1234"])   
    mkt_1 == mkt_2
}

test mt_creation_2 () {
    let mkt_1 = Node(#"d307075d4a2c34a02d4c48a4bf26ccc38636f36d8143d219b7c9dcccdfdea43b",Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"), Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"))
    let mkt_2 = create_merkle_tree([#"1234",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678"])   
    mkt_1 == mkt_2
}


//fn merkle_proof (_root_hash: Hash<Blake2b_256, ByteArray>, leaf: MerkleTree, remaining_proofs: List<Hash<Blake2b_256, ByteArray>>) -> Hash<Blake2b_256, ByteArray> 
fn merkle_proof (leaf: MerkleTree, remaining_proofs: List<Hash<Blake2b_256, ByteArray>>) -> Hash<Blake2b_256, ByteArray> {
    expect Leaf(leaf_hash, _) = leaf

    let proof = list.foldl(remaining_proofs, leaf_hash,
        fn(element, total) { 
            blake2b_256(bytearray.concat(element, total))
    })
    proof 
}

fn get_mk_root_hash (mt: MerkleTree) -> Hash<Blake2b_256, ByteArray> {
    expect Node(hash,..) = mt
    hash
}

test check_hash_creation_1 () {
    expect Some(Leaf(h, ..)) = to_leaf([#"1234"]) |> list.head()
    blake2b_256(#"1234") ==  h
}

test check_hash_creation_2 () {
    let leaf_content = #"1234"
    expect [Leaf(leaf_hash, ..)] = [leaf_content] |> to_leaf()
    let mkt = create_merkle_tree([leaf_content,leaf_content])
    let mkt_hash_root = get_mk_root_hash(mkt)

    blake2b_256(bytearray.concat(leaf_hash, leaf_hash)) == mkt_hash_root
}

test merkle_proof_1 () {
    let mt = Node(#"d307075d4a2c34a02d4c48a4bf26ccc38636f36d8143d219b7c9dcccdfdea43b",Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"), Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"))
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"1234"])
    let path_hashes = [#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11"]

    merkle_proof(leaf_to_prove, path_hashes) == root_hash
}

test merkle_proof_2 () {
    let mt = create_merkle_tree([#"1234",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"1234"])
    let path_hashes = [#"909f6b08ec0685c29277a83e5f08295a402011dd31a1002d1c4c7d54bdd06b70", #"422ca8254cfb947925c1b56ff59359389afa80975e0b1fd238f10fa1a8cbd21b", #"e0e49e69cd6a485eca8fdd0d530933cccbd3e8d3442f04166fbb2104a7e37f23"]

    merkle_proof(leaf_to_prove, path_hashes) == root_hash
}

