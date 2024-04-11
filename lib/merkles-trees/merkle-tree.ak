use aiken/hash.{Hash, blake2b_256, Blake2b_256}
use aiken/list
use aiken/bytearray
use aiken/math


type MerkleTree {
    Node(Hash<Blake2b_256, ByteArray>, MerkleTree, MerkleTree)
    Leaf(Hash<Blake2b_256, ByteArray>,ByteArray)
}

type Direction {
    Left 
    Right
}

// Creation of Merkle Tree

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

// Get size(depth) of the MT given the leaf 

fn get_size (leaf_quantity: Int) -> Int {
    math.log(leaf_quantity,2)
}

test get_size_1 () {
    get_size(4) == 2
}

// Get path of a lead given its index

fn get_path_rec (mt_size: Int, element_index: Int, path: List<Direction>) -> List<Direction>  {
    let pivot_node = mt_size / 2

    if mt_size == 0 {
        []
    } else if pivot_node == 1 {
        when element_index % 2 is {
            1 -> list.push(path, Left) 
            0 -> list.push(path, Right) 
            _ -> error ""
        }
    } else if element_index <= pivot_node {
        let result = list.push(path, Left)
        get_path_rec(pivot_node, element_index, result)
    } else {
        let result = list.push(path, Right)
        get_path_rec(pivot_node, element_index - pivot_node, result)
    }
}

fn get_path (mt_level: Int, element_index: Int) -> List<Direction> {
    let leaf_quantity = math.pow(2,mt_level)
    get_path_rec(leaf_quantity, element_index, [])
}

test get_path_1 () {
    get_path(1,1) == [Left]
}
test get_path_2 () {
    get_path(1,2) == [Right]
}

test get_path_3 () {
    get_path(2,1) == [Left,Left]
}
test get_path_4 () {
    get_path(2,2) == [Right,Left]
}

test get_path_5 () {
    get_path(2,3) == [Left,Right]
}
test get_path_6 () {
    get_path(2,4) == [Right,Right]
}

test get_path_7 () {
    get_path(3,1) == [Left,Left,Left]
}

test get_path_8 () {
    get_path(3,7) == [Left,Right,Right]
}
test get_path_9 () {
    get_path(3,4) == [Right,Right,Left]
}

test get_path_10 () {
    get_path(3,8) == [Right,Right,Right]
}

test get_path_11 () {
    get_path(0,1) == []
}


fn get_mk_depth_rec (mt: MerkleTree, count: Int) -> Int {
    when mt is {
        Node(_,node,_) -> get_mk_depth_rec(node,count + 1)
        Leaf(..) -> count 
    }
}

fn get_mk_depth(mt: MerkleTree ) -> Int {
    get_mk_depth_rec(mt, 0)
}

test get_mk_depth_1 () {
    let mt = create_merkle_tree([#"1234"])   
    get_mk_depth(mt) == 0
}

test get_mk_depth_2 () {
    let mt = create_merkle_tree([#"1234",#"1234"])   
    get_mk_depth(mt) == 1
}

test get_mk_depth_3 () {
    let mt = create_merkle_tree([#"1234",#"1234",#"1234",#"1234"])   
    get_mk_depth(mt) == 2
}

test get_mk_depth_4 () {
    let mt = create_merkle_tree([#"1234",#"1234",#"1234",#"1234",#"1234",#"1234",#"1234",#"1234"])   
    get_mk_depth(mt) == 3
}


fn merkle_proof_rec(start: Hash<Blake2b_256, ByteArray>, remaining_hashes: List<Hash<Blake2b_256, ByteArray>>, path: List<Direction>) -> Hash<Blake2b_256, ByteArray> {
    
    when (path, remaining_hashes) is {
        ([],[]) -> start
        ([_x],[]) -> error "arg1 error" 
        ([],[_y]) -> error "arg2 errr"
        _ -> {
            expect Some(list_head) = list.head(remaining_hashes)
            expect Some(proofs_tail) = list.tail(remaining_hashes)
            expect Some(direction) = list.head(path)
            expect Some(paths_tail) = list.tail(path)
            
            if direction == Left {
                let result = blake2b_256(bytearray.concat(start,list_head))
                merkle_proof_rec(result,proofs_tail,paths_tail)
            } else {
                let result = blake2b_256(bytearray.concat(list_head, start))
                merkle_proof_rec(result,proofs_tail,paths_tail)
            }
        }
    }

}


//fn merkle_proof (_root_hash: Hash<Blake2b_256, ByteArray>, leaf: MerkleTree, remaining_hashes: List<Hash<Blake2b_256, ByteArray>>) -> Hash<Blake2b_256, ByteArray> 
fn merkle_proof (leaf: MerkleTree, remaining_hashes: List<Hash<Blake2b_256, ByteArray>>, path: List<Direction> ) -> Hash<Blake2b_256, ByteArray> {
    expect Leaf(leaf_hash, _) = leaf
    merkle_proof_rec(leaf_hash, remaining_hashes, path)
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
    let leaf_content = #"5678"
    expect [leaf] = [leaf_content] |> to_leaf()
    expect Leaf(_leaf_hash, ..) = leaf

    let mkt = create_merkle_tree([#"5678",#"5678"])
    let path_hashes = [#"909f6b08ec0685c29277a83e5f08295a402011dd31a1002d1c4c7d54bdd06b70"]
    let mkt_hash_root = get_mk_root_hash(mkt)

    let depth = get_mk_depth(mkt)
    let path = get_path(1,depth)

    merkle_proof(leaf, path_hashes, path) == mkt_hash_root
}

test merkle_proof_2 () {
    let mt = Node(#"d307075d4a2c34a02d4c48a4bf26ccc38636f36d8143d219b7c9dcccdfdea43b",Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"), Leaf(#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11", #"1234"))
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"1234"])
    let path_hashes = [#"35826d51e070a6d9ac7e69df455191dc02f66678879a12511f5a91d8befacb11"]

    let depth = get_mk_depth(mt)
    let path = get_path(1,depth)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}


test merkle_proof_3 () {
    let mt = create_merkle_tree([#"1234",#"5678",#"5678",#"5678"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"1234"])
    let path_hashes = [#"909f6b08ec0685c29277a83e5f08295a402011dd31a1002d1c4c7d54bdd06b70",#"422ca8254cfb947925c1b56ff59359389afa80975e0b1fd238f10fa1a8cbd21b"]

    let depth = get_mk_depth(mt)
    let path = get_path(depth,1)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}


test merkle_proof_4 () {
    let mt = create_merkle_tree([#"1234",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678",#"5678"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"1234"])
    let path_hashes = [#"909f6b08ec0685c29277a83e5f08295a402011dd31a1002d1c4c7d54bdd06b70", #"422ca8254cfb947925c1b56ff59359389afa80975e0b1fd238f10fa1a8cbd21b", #"e0e49e69cd6a485eca8fdd0d530933cccbd3e8d3442f04166fbb2104a7e37f23"]

    let depth = get_mk_depth(mt)
    let path = get_path(depth,1)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}


// Just that the compiler prints the data.
test fail_mkt () {
    create_merkle_tree([#"1111",#"2222",#"3333",#"4444",#"5555",#"6666",#"7777",#"8888"]) == create_merkle_tree([#"1111",#"2222"])
}

test merkle_proof_5 () {
    let mt = create_merkle_tree([#"1111",#"2222",#"3333",#"4444",#"5555",#"6666",#"7777",#"8888"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"3333"])
    let path_hashes = [#"52c2d9812b24bc8bdfed1ab234270fb132d62a94493ba726107144a2eed8a178", #"2577120316c29d5c366a41b2ddcff823c2e563b2b24cc04dc29c950dd52d57e3", #"ac5e048c8c9c4bd7db69fdda577a596c8d2c91b8121d8321651cdd60fbc5059f"]

    let depth = get_mk_depth(mt)
    let path = get_path(depth,3)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}

test merkle_proof_6 () {
    let mt = create_merkle_tree([#"1111",#"2222",#"3333",#"4444",#"5555",#"6666",#"7777",#"8888"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"7777"])
    let path_hashes = [#"2c25df7238f2ae024b6fa59b877591920b831022aa8fb976eee1ba59412644e0", #"d94eeb2186e912883151875c33880913c8b56487c0f820c3e7336bf43b04a1a8", #"3611c9daa834eaf837f78bd4ce79b82a2c5ef639d9e8558a584fa168f797d6d2"]

    let depth = get_mk_depth(mt)
    let path = get_path(depth,7)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}

test merkle_proof_7 () {
    let mt = create_merkle_tree([#"1111",#"2222",#"3333",#"4444",#"5555",#"6666",#"7777",#"8888"])
    let root_hash = get_mk_root_hash(mt)

    expect [leaf_to_prove] = to_leaf([#"4444"])
    let path_hashes = [#"ef97c9e36f5e33370c795599501e8f834363461eb001fd227831992c57b5bedf",#"2577120316c29d5c366a41b2ddcff823c2e563b2b24cc04dc29c950dd52d57e3", #"ac5e048c8c9c4bd7db69fdda577a596c8d2c91b8121d8321651cdd60fbc5059f"]

    let depth = get_mk_depth(mt)
    let path = get_path(depth,4)

    merkle_proof(leaf_to_prove, path_hashes, path) == root_hash
}