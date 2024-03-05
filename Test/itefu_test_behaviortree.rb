=begin
  BehaviorTreeのテストコード
=end
class Itefu::Test::BehaviorTree < Itefu::UnitTest::TestCase

  module Node
    include Itefu::BehaviorTree::Node
  end
  
  module Status
    include Itefu::BehaviorTree::Node::Status
  end
  
  # BT Manager
  class Manager
    include Itefu::BehaviorTree::Manager
    def add_bt_tree2(klass, context = nil, *args, &block)
      add_bt_tree(klass, context, *args, &block).child
    end
  end
  
  # 任意のステータスを返すノード
  class MockNode < Node::Base
    attr_accessor :mock_status
    attr_accessor :processed
    def initialize(s = Status::SUCCESS)
      self.mock_status = s
      self.processed = 0
    end
    def on_node_process
      self.processed += 1
      self.mock_status
    end
  end
  
  # Importer
  class MockImporter < Node::ImporterBase
    def script_text(script_id)
      script_id
    end
  end
  
  def setup
    @manager = Manager.new
  end
  
  def teardown
    @manager.finalize_bt
  end
  
  def test_decorator
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Decorator)
    node.push manager.add_bt_tree2(Node::Decorator).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Decorator).tap {|n|
        n.join_node(MockNode, Status::FAILURE)
      }
    node.push manager.add_bt_tree2(Node::Decorator).tap {|n|
        n.join_node(MockNode, Status::RUNNING)
      }
    manager.update_bt_trees
    
    assert_equal(Status::SUCCESS, node[0].status)
    assert_equal(Status::SUCCESS, node[1].status)
    assert_equal(Status::FAILURE, node[2].status)
    assert_equal(Status::RUNNING, node[3].status)
  end
  
  def test_conditional
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Conditional, nil, nil)

    node.push manager.add_bt_tree2(Node::Conditional, nil, proc {|n|
        false
      }).tap {|n|
        n.join_node(MockNode)
      }
    node.push manager.add_bt_tree2(Node::Conditional, nil, proc {|n|
        true
      }).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Conditional, nil, proc {|n|
        true
      }).tap {|n|
        n.join_node(MockNode, Status::FAILURE)
      }
    node.push manager.add_bt_tree2(Node::Conditional, nil, proc {|n|
        true
      }).tap {|n|
        n.join_node(MockNode, Status::RUNNING)
      }
    manager.update_bt_trees

    assert_equal(Status::FAILURE, node[0].status)
    assert_equal(Status::FAILURE, node[1].status)
    assert_equal(Status::READY,   node[1].child.status)
    assert_equal(Status::SUCCESS, node[2].status)
    assert_equal(Status::FAILURE, node[3].status)
    assert_equal(Status::RUNNING, node[4].status)
  end
  
  def test_inverter
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Inverter)
    node.push manager.add_bt_tree2(Node::Inverter).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Inverter).tap {|n|
        n.join_node(MockNode, Status::FAILURE)
      }
    node.push manager.add_bt_tree2(Node::Inverter).tap {|n|
        n.join_node(MockNode, Status::RUNNING)
      }
    manager.update_bt_trees

    assert_equal(Status::FAILURE, node[0].status)
    assert_equal(Status::FAILURE, node[1].status)
    assert_equal(Status::SUCCESS, node[2].status)
    assert_equal(Status::RUNNING, node[3].status)
  end
  
  def test_succeeder
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Succeeder)
    node.push manager.add_bt_tree2(Node::Succeeder).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Succeeder).tap {|n|
        n.join_node(MockNode, Status::FAILURE)
      }
    node.push manager.add_bt_tree2(Node::Succeeder).tap {|n|
        n.join_node(MockNode, Status::RUNNING)
      }
    manager.update_bt_trees
    
    assert_equal(Status::SUCCESS, node[0].status)
    assert_equal(Status::SUCCESS, node[1].status)
    assert_equal(Status::SUCCESS, node[2].status)
    assert_equal(Status::RUNNING, node[3].status)
  end
  
  def test_untilfail
    manager = @manager
    node0 = manager.add_bt_tree2(Node::UntilFail)
    node1 = manager.add_bt_tree2(Node::UntilFail).tap {|n|
        n.join_node(MockNode)
      }
    mock1 = node1.child

    mock1.mock_status = Status::SUCCESS
    manager.update_bt_trees
    assert_equal(Status::RUNNING, node0.status)
    assert_equal(Status::RUNNING, node1.status)
    assert_equal(1, mock1.processed)

    mock1.mock_status = Status::RUNNING
    manager.update_bt_trees
    assert_equal(Status::RUNNING, node0.status)
    assert_equal(Status::RUNNING, node1.status)
    assert_equal(2, mock1.processed)

    mock1.mock_status = Status::FAILURE
    manager.update_bt_trees
    assert_equal(Status::RUNNING, node0.status)
    assert_equal(Status::SUCCESS, node1.status)
    assert_equal(3, mock1.processed)
  end
  
  def test_repeater
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Repeater, nil, 3).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Repeater, nil, nil).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Repeater, nil, 0).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }

    manager.update_bt_trees
    assert_equal(Status::RUNNING, node[0].status)
    assert_equal(Status::RUNNING, node[1].status)
    assert_equal(Status::SUCCESS, node[2].status)
    assert_equal(0, node[2].child.processed)
    node[0].child.mock_status = node[1].child.mock_status = Status::FAILURE
    manager.update_bt_trees
    assert_equal(Status::FAILURE, node[0].status)
    assert_equal(Status::RUNNING, node[1].status)

    node[0].child.mock_status = Status::SUCCESS
    mock = node[0].child
    mock.processed = 0
    manager.update_bt_trees
    assert_equal(Status::RUNNING, node[0].status)
    assert_equal(1, mock.processed)
    manager.update_bt_trees
    assert_equal(Status::RUNNING, node[0].status)
    assert_equal(2, mock.processed)
    manager.update_bt_trees
    assert_equal(Status::SUCCESS, node[0].status)
    assert_equal(3, mock.processed)
  end
  
  def test_weight
    manager = @manager
    node = manager.add_bt_tree2(Node::Weight, nil, 0)
    assert_equal(1, node.weight)
    node = manager.add_bt_tree2(Node::Weight, nil, -1)
    assert_equal(1, node.weight)
    node = manager.add_bt_tree2(Node::Weight, nil, 1)
    assert_equal(1, node.weight)
    node = manager.add_bt_tree2(Node::Weight, nil, 2.3)
    assert_equal(2.3, node.weight)
    node = manager.add_bt_tree2(Node::Weight, nil, Rational(4,5))
    assert_equal(1, node.weight)
    node = manager.add_bt_tree2(Node::Weight, nil, Rational(3,2))
    assert_equal(1.5, node.weight)
  end
  
  def test_lazy
    manager = @manager
    node = manager.add_bt_tree2(Node::Lazy)
    node.join_node(Node::Decorator).join_node(MockNode)
    
    assert_nil(node.child)
    manager.update_bt_trees
    assert_instance_of(Node::Decorator, node.child)
    assert_instance_of(MockNode, node.child.child)
  end
  
  def test_initializer
    manager = @manager
    node = []
    node.push manager.add_bt_tree2(Node::Initializer)
    node.push manager.add_bt_tree2(Node::Initializer).tap {|n|
        n.join_node(MockNode, Status::SUCCESS)
      }
    node.push manager.add_bt_tree2(Node::Initializer).tap {|n|
        n.join_node(MockNode, Status::FAILURE)
      }
    node.push manager.add_bt_tree2(Node::Initializer).tap {|n|
        n.join_node(MockNode, Status::RUNNING)
      }

    manager.update_bt_trees
    assert_equal(Status::SUCCESS, node[0].status)
    assert_equal(Status::SUCCESS, node[1].status)
    assert_equal(Status::FAILURE, node[2].status)
    assert_equal(Status::RUNNING, node[3].status)
    node[1..-1].each.with_index(1) do |n, i|
      assert_equal(1, n.child.processed, "i=#{i}")
    end

    manager.update_bt_trees
    node[0..-2].each.with_index do |n, i|
      assert_equal(Status::FAILURE, n.status, "i=#{i}")
    end
    assert_equal(1, node[1].child.processed)
    assert_equal(1, node[2].child.processed)
    assert_equal(2, node[3].child.processed)
    assert_equal(Status::RUNNING, node[3].status)
  end
  
  def test_composite
    manager = @manager
    node = manager.add_bt_tree2(Node::Composite)
    10.times {
      node.join_node(MockNode, rand(2) == 0 ? Status::FAILURE : Status::SUCCESS)
    }
    manager.update_bt_trees
    node.children.each.with_index do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::SUCCESS, node.status)
  end
  
  def test_sequence
    manager = @manager
    node = manager.add_bt_tree2(Node::Sequence)
    10.times {
      node.join_node(MockNode, rand(2))
    }
    
    node.children.each {|n| n.mock_status = Status::SUCCESS }
    manager.update_bt_trees
    node.children.each.with_index do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::SUCCESS, node.status)
    
    node.children[4].mock_status = Status::RUNNING
    manager.update_bt_trees
    node.children[0..4].each.with_index do |n, i|
      assert_equal(2, n.processed, "i=#{i}")
    end
    node.children[5..-1].each.with_index(5) do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::RUNNING, node.status)

    node.children[4].mock_status = Status::SUCCESS
    node.children[4].processed -= 1
    node.children[8].mock_status = Status::FAILURE
    manager.update_bt_trees
    node.children[0..8].each.with_index do |n, i|
      assert_equal(2, n.processed, "i=#{i}")
    end
    node.children[9..-1].each.with_index(9) do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::FAILURE, node.status)
  end
  
  def test_selector
    manager = @manager
    node = manager.add_bt_tree2(Node::Selector)
    10.times {
      node.join_node(MockNode, rand(2))
    }
    
    node.children.each {|n| n.mock_status = Status::FAILURE }
    manager.update_bt_trees
    node.children.each.with_index do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::FAILURE, node.status)
    
    node.children[4].mock_status = Status::RUNNING
    manager.update_bt_trees
    node.children[0..4].each.with_index do |n, i|
      assert_equal(2, n.processed, "i=#{i}")
    end
    node.children[5..-1].each.with_index(5) do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::RUNNING, node.status)

    node.children[4].mock_status = Status::FAILURE
    node.children[4].processed -= 1
    node.children[8].mock_status = Status::SUCCESS
    manager.update_bt_trees
    node.children[0..8].each.with_index do |n, i|
      assert_equal(2, n.processed, "i=#{i}")
    end
    node.children[9..-1].each.with_index(9) do |n, i|
      assert_equal(1, n.processed, "i=#{i}")
    end
    assert_equal(Status::SUCCESS, node.status)
  end
  
  def test_random
    manager = @manager
    node = manager.add_bt_tree2(Node::Random)
    10.times {
      node.join_node(MockNode)
    }
    manager.update_bt_trees
    
    node.children.one? {|n|
      n.processed == 1
    }
  end
  
  def test_leaf
    manager = @manager
    node = manager.add_bt_tree2(Node::Leaf)
    manager.update_bt_trees
    assert_equal(Status::SUCCESS, node.status)
  end
  
 def test_adhockaction
   manager = @manager
   node = []
   node.push manager.add_bt_tree2(Node::AdHocAction)
   node.push manager.add_bt_tree2(Node::AdHocAction) {
     }
   node.push manager.add_bt_tree2(Node::AdHocAction) {
        succeed
     }
   node.push manager.add_bt_tree2(Node::AdHocAction) {
        fail
     }
   node.push manager.add_bt_tree2(Node::AdHocAction) {
        suspend
        fail
     }

   manager.update_bt_trees
   assert_equal(Status::SUCCESS, node[0].status)
   assert_equal(Status::SUCCESS, node[1].status)
   assert_equal(Status::SUCCESS, node[2].status)
   assert_equal(Status::FAILURE, node[3].status)
   assert_equal(Status::RUNNING, node[4].status)

   manager.update_bt_trees
   assert_equal(Status::SUCCESS, node[0].status)
   assert_equal(Status::SUCCESS, node[1].status)
   assert_equal(Status::SUCCESS, node[2].status)
   assert_equal(Status::FAILURE, node[3].status)
   assert_equal(Status::FAILURE, node[4].status)
 end
 
 def test_importerbase
   manager = @manager
   node = manager.add_bt_tree2(MockImporter, nil, <<-EOS)
      importer.join_node(Base)
   EOS
   assert_instance_of(Node::Base, node.child)
 end

end
