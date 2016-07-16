require 'busted.runner'()

package.path=package.path .. ';?.lua'
require 'dsl'

describe('Graph functionality testing', function()
           local a = Var 'a'
           local b = Var 'b'

           local res = 3 * a + b + 5 * a -- + 10 * b

           it('evaluator works', function()
                local val, cost = eval_graph(res, { a = 10, b = 20 })
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

describe('Transform / ', function()
          T = require 'transform'

           it('should detect commutativity', function()
                local g1 = Num(1) + Num(2)
                local g2 = Num(2) * Var('a')

                local trans1 = T.find_transform_sites(g1, 'commutativity')
                assert.are.same({ { rule = 'commutativity', path = {}},  }, trans1)

                local trans2 = T.find_transform_sites(g2, 'commutativity')
                assert.are.same({ { rule = 'commutativity', path = {}} }, trans2)

                local g3 = g1 + g2
                local trans3 = T.find_transform_sites(g3, 'commutativity')

                assert.is.equal(3,#trans3, 'three sites')
           end)

           test('apply commutativity', function()
                  local g1 = Num(1) + Num(2)

                  local trans = T.find_transform_sites(g1)[1]
                  T.apply_transform(g1, trans)
                  assert.are.same(Num(2) + 1, g1)

           end)

           test('apply commutativity to other graph', function()
                  local g1 = Num(1) + Num(2)
                  local g2 = Num(3) + Num(4)

                  local trans = T.find_transform_sites(g1)[1]
                  T.apply_transform(g1, trans)
                  assert.are.same(Num(2) + 1, g1)
                  T.apply_transform(g2, trans)
                  assert.are.same(Num(4) + 3, g2)
           end)

           test('detect assoc_l', function()
                  local g1 = Num(1) + 2 + 3

                  local trans1 = T.find_transform_sites(g1, 'assoc_l')

                  local n = 0
                  assert.is.equal(1, #trans1)
                  T.apply_transform(g1, trans1[1])
                  assert.are.same(Num(1) + (Num(2) + 3), g1)
           end)

           test('detect assoc_r', function()
                  local g1 = Num(1) + (Num(2) + 3)

                  local trans1 = T.find_transform_sites(g1, 'assoc_r')

                  assert.is.equal(1, #trans1)
                  T.apply_transform(g1, trans1[1])
                  assert.are.same((Num(1) + Num(2)) + 3, g1)
           end)

           test('overlapping assoc', function()
                  local g0 = Num(1) + 2
                  local g1 = g0 + 5
                  local g2 = g0 * g1

                  local trans1 = T.find_transform_sites(g2, 'assoc_l')

                  assert.is.equal(1, #trans1)
                  local v1 = eval_graph(g2)
                  T.apply_transform(g2, trans1[1])
                  local v2 = eval_graph(g2)
                  assert.are.equal(v1,v2)
           end)

           test('distributive', function()
                  local g = Num(2) * (Num(3) + 4)
                  local dist_site = T.find_transform_sites(g,'distrib')
                  assert.True(type(dist_site) == 'table')
                  assert.is.equal(1, #dist_site)

                  T.apply_transform(g, dist_site[1])
                  assert.are.same(Num(2) * 3 + Num(2)*4, g)
           end)

           test('factorize', function()
                  local g1 = Num(2) * (Num(3) + 4)
                  local g2 = Num(2) * 3 + Num(2)*4
                  local dist_site = T.find_transform_sites(g2,'factor')
                  assert.True(type(dist_site) == 'table')
                  assert.is.equal(1, #dist_site)

                  T.apply_transform(g2, dist_site[1])
                  assert.are.same(g1, g2)
           end)
end)
