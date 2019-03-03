begin 
    require 'DeepDarkFantasy'
rescue 
    require_relative '../lib/DeepDarkFantasy.rb'
end

SEP = "-------------------------------"

#Test vector 
v1 = DDF::ColVector[1, 2, 3]
p v1
p 1 + v1
p 3 * v1 
p 1 / v1
p v1
puts SEP
v2 = [2, 3, 4].to_v(false)  #v2 is a DDF::ColVector
p v2
p v2 * v1
p v2 - v1
p v1 + v2
p Math.sigmoid(v1 + v2) #broadcast 
p Math.exp(v2)          #broadcast
p v2

#Test Matrix
puts SEP
m1 = DDF::Matrix.from_stdlib_matrix(Matrix[[1, 2, 3], [4, 5, 6], [7, 8, 9]])
p m1
p 10 + m1  
p m1 * 2
p (m1 * DDF::ColVector[1, 1, 1]).as_vector
p (m1 * DDF::Matrix.from_stdlib_matrix(Matrix[[1, 3], [0, 1], [1, 2]]))

#Random Test
puts SEP
p Math.softmax(DDF::RowVector[1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0])