require 'busted.runner'()

package.path=package.path .. ';?.lua'
require 'dsl'

describe('Graph functionality testing', function()
           local a = Var 'a'
           local b = Var 'b'

           local res = 3 * a + b + 5 * a -- + 10 * b

           it('evaluator works', function()
                local val, cost = eval_node(res, { a = 10, b = 20 })
                assert.are.equal(100, val)
                assert.are.equal(22, cost)
           end)
           it('should render something', function()
                local dot_name = '/tmp/g.dot'
                render_graph(res, dot_name)
                local res = os.remove(dot_name)
                assert.True(res, 'dot should be created')
           end)
end)
