require 'matrix'

module DDF
    #class matrix, basic operations.
    class Matrix 
        attr_reader :data
        attr_reader :row_size, :col_size
        # initializing method, m indicates number of rows, n indicates number of columns.
        def initialize(m, n)
            @row_size = m
            @col_size = n
            @data = Array.new(m) {Array.new(n) {0.0}}
        end

        # getter
        def [](i, j)
            @data[i][j]
        end

        # setter
        def []=(i, j, v)
            @data[i][j] = v.to_f
        end

        # data array setter
        # Do not recommend call by user directly
        def data=(d)
            @data = d
            @row_size = d.size
            @col_size = d[0].size
        end

        # comparation equal
        def ==(m)
            return false if !m.is_a?(DDF::Matrix)
            return false if self.col_size != m.col_size || self.row_size != m.row_size
            @row_size.times {|i|
                @col_size.times {|j|
                    return false if @data[i][j] != m[i, j]
                }
            }            
            return true
        end

        # comparation not equal
        def !=(m)
            return !(self == m)
        end

        # Get all elements in i-th row (data is cloned)
        def row(i)
            DDF::RowVector[*@data[i].clone]
        end

        # Get all elements in i-th column (data is cloned)
        def col(i)
            r = []
            @row_size.times {|j|
                r << @data[j][i]
            }
            DDF::ColVector[*r]
        end

        # for each element A_ij, A_ij := op(A_ij, m or m_i or m_ij)
        # as for different type of m(Numeric/Vector/Matrix), it will perform differently.
        def each_with_operator(m, op)
            case m
            when Numeric
                @data.each {|row| row.each_with_index {|_, i| row[i] = op.call(row[i], m)}}
            when DDF::Matrix 
                if self.row_size != m.row_size || self.col_size != m.col_size
                    raise ArgumentError, "DDF::Matrix#each_with_operator, can not operate the two matrix."
                else
                    @data.each_with_index{|_, i| @data[i].each_with_index{|__, j| @data[i][j] = op.call(@data[i][j], m[i, j])}}
                end
            when DDF::RowVector
                if(m.col_size != self.col_size) 
                    raise ArgumentError, "DDF::Matrix#each_with_operator, can not operate the matrix and the row vector"
                else 
                    @data.each {|row| row.each_with_index {|_, i| row[i] = op.call(row[i], m[i])}}
                end
            when DDF::ColVector
                if(m.row_size != self.row_size)
                    raise ArgumentError, "DDF::Matrix#each_with_operator, can not operate the matrix and the col vector"
                else 
                    @col_size.times {|col| 
                        @row_size.times {|i|
                            @data[i][col] = op.call(@data[i][col], m[i])
                        }
                    }
                end
            end
            return self
        end

        # + operation
        def +(m)
            t = self.clone
            t.each_with_operator(m, lambda {|x, y| x + y})
        end

        # - operation
        def -(m) 
            t = self.clone
            t.each_with_operator(m, lambda {|x, y| x - y})
        end

        # * operation
        # if Argument 'm' is a Numeric, each element of the matrix will multiply it.
        # if 'm' is a Matrix(or a Vector), this method will perform matrix multiply.
        def mul(m)
            case m
            when Numeric
                each_with_operator(m, lambda {|x, y| x * y})
            when Matrix
                if self.col_size != m.row_size
                    raise ArgumentError, "DDF::Matrix#*=:Can not perform matrix multiply on the two matrix"
                end
                d = Array.new(self.row_size) {Array.new(m.col_size) {0.0}}
                self.row_size.times {|i|
                    m.col_size.times {|j|
                        self.col_size.times {|k|
                            d[i][j] += self[i, k] * m[k, j]
                        }
                    }
                }
                self.data = d
            end
            return self
        end
        # * operation
        def *(m)
            t = self.clone
            t.mul(m)
        end
        # division，argument m should be a numeric
        def /(m)
            t = self.clone
            t.each_with_operator(m, lambda {|x, y| x / y})
        end

        # magic
        def method_missing(name, *arg, &block)
            begin 
                m = ::Matrix.instance_method(name)
            rescue 
                super(name, *arg, &block)
            end
            m.bind(::Matrix.build(@row_size, @col_size) {|i, j|
                @data[i][j]
            }).call(*arg, &block)
        end

        # Create DDF::Matrix from Matrix(in ruby stdlib)
        # example : v = DDF::Matrix.from_stdlib_matrix(Matrix[[1, 2, 3], [4, 5, 6], [7, 8, 9]])
        def self.from_stdlib_matrix(m) 
            x = DDF::Matrix.new(m.row_size, m.column_size)
            x.row_size.times {|i| 
                x.col_size.times {|j|
                    x[i, j] = m[i, j].to_f
                }
            }
            x
        end

        def clone 
            x = self.class.new(@row_size, @col_size)
            @row_size.times {|i|
                @col_size.times {|j|
                    x[i, j] = self[i, j]
                }
            }
            x
        end

        #Convert self to a vector type if possible
        def as_vector 
            if self.col_size == 1
                return DDF::ColVector[*col(0)]
            elsif self.row_size == 1
                return DDF::RowVector[*row(0)]
            else 
                raise ArgumentError, "Can not convert the matrix to a vector"
            end
        end

        #Convert self to a scalar if possible
        def as_scalar
            if self.col_size == 1 && self.row_size == 1
                return @data[0][0]
            else
                raise ArgumentError, "Can not convert the matrix/vector to a scalar"
            end
        end

        def transpose!
            d = Array.new(@col_size) {Array.new(@row_size)}
            (0...@col_size).each {|i| 
                (0...@row_size).each {|j| 
                    d[i][j] = @data[j][i]
                }
            }
            self.data = d
            return self
        end

        def transpose
            t = self.clone
            return t.transpose!
        end

        def inspect
            "#{@row_size} rows, #{@col_size} columns\n[#{@data.map{|x| x.to_s}.join("\n ")}]\n"
        end
    end

    class RowVector < DDF::Matrix
        def self.[](*a)
            x = self.new(a.size)
            a.size.times {|i| x[i] = a[i].to_f}
            x
        end

        def initialize(n)
            super(1, n)
        end
        def [](*arg)
            return arg.size == 1 ? super(0, arg[0]) : super(*arg)
        end
        def []=(*arg)
            return arg.size == 2 ? super(0, arg[0], arg[1]) : super(*arg)
        end
        def size 
            self.col_size
        end
        alias :old_mul :*
        def *(m)
            if m.is_a?(DDF::RowVector) 
                v = DDF::RowVector.new(self.size)
                self.size.times {|i| v[i] = self[i] * m[i]}      
                return v
            else
                return old_mul(m)
            end
        end
        def clone 
            x = self.class.new(size)
            x.size.times {|i| x[i] = self[i]}
            x
        end

        #RowVector transpose to an ColVector
        def transpose
            x = ColVector.new(size)
            x.size.times {|i| x[i] = self[i]}
            x
        end
        include Enumerable
        def each
            self.size.times {|i| yield(self[i]) }
        end
        def to_v(_) 
            self
        end
    end
    class ColVector < DDF::Matrix
        def self.[](*a)
            x = self.new(a.size)
            a.size.times {|i| x[i] = a[i].to_f}
            x
        end
        
        def initialize(n)
            super(n, 1)
        end
        def [](*arg)
            return arg.size == 1 ? super(arg[0], 0) : super(*arg)
        end
        def []=(*arg)
            return arg.size == 2 ? super(arg[0], 0, arg[1]) : super(*arg)
        end
        def size 
            self.row_size
        end
        alias :old_mul :*
        def *(m)
            if m.is_a?(DDF::ColVector)
                v = DDF::ColVector.new(self.size)
                self.size.times {|i| v[i] = self[i] * m[i]}      
                return v
            else
                return old_mul(m)
            end
        end
        def clone 
            x = self.class.new(size)
            x.size.times {|i| x[i] = self[i]}
            x
        end

        #ColVector transpose to an RowVector
        def transpose
            x = RowVector.new(size)
            x.size.times {|i| x[i] = self[i]}
            x
        end
        include Enumerable
        def each
            self.size.times {|i| yield(self[i]) }
        end
        def to_v(_)
            self
        end
    end

=begin
    # Apply function 'f' on two vector
    # 'f' is a function which recieves two scalars as independent variables.
    # a, b are two vectors.
    # DDF.broad_apply(f, a, b) returns a vector c[i] = f(a[i], b[i]) for each i.
    def self.broad_apply(f, a, b)
        if x.size != y.size
            raise ArgumentError, "can not boradcast"
        end
        r = []
        x.each_with_index {|_, i| r << f.call(x[i], y[i])}
        return r
    end
=end



end

# Patch to class Array, add 'to_v' method
class ::Array 
    # to_v, convert an array to a vector is possible. parameter 'is_row_vector' indicates whether convert to a row vector.
    def to_v(is_row_vector = false)
        return is_row_vector ? DDF::RowVector[*self] : DDF::ColVector[*self]
    end
end

# Patch to class Integer and Float, make their instances be able to operate with DDF::Matrix
[Integer, Float].each {|klass| klass.instance_exec {
    [[:__add, :+, lambda {|x,y| x+y}], [:__sub, :-, lambda {|x,y| y-x}], [:__mul, :*, lambda {|x,y| x*y}], [:__div, :/, lambda {|x,y| y/x}]].each {|new_name, old_name, op|
        alias_method(new_name, old_name)
        define_method(old_name) {|arg|
            if Math.is_vector?(arg)
                return arg.to_v(arg.is_a?(DDF::RowVector)).clone.each_with_operator(self, op)
            else
                return self.method(new_name).call(arg)
            end
        }
    }
}}


# Patch to module Math, make its module functions can operate on Matrix or Vector
# For example: if there is a m = DDF::Matrix [[1.0, 10.0, 100.0]]
# Math.log10(m) returns [[0.0, 1.0, 2.0]]
Math.instance_exec { 
    class << self    
    [:log, :log2, :log10, :cbrt, :frexp, :ldexp,
         :hypot, :erf, :erfc, :gamma, :lgamma, :sqrt, 
         :atan2, :cos, :sin, :tan, :acos, :asin, :atan, 
         :cosh, :sinh, :tanh, :acosh, :asinh, :atanh,
          :exp].each {|m|
            new_name = ("__" + m.to_s).to_sym
            alias_method(new_name, m)
            define_method(m) {|arg|
                nm = self.method(new_name)
                if Math.is_vector?(arg)
                    res = arg.to_v(arg.is_a?(DDF::RowVector)).clone 
                    res.row_size.times {|i|
                        res.col_size.times {|j|
                            res[i, j] = nm.call(res[i, j])
                        }
                    }
                    return res
                else
                    nm.call(arg)
                end
            } 
    }
    end
}

module Math 
    SIGMOID = lambda {|x, _| 1.0 / (1.0 + Math.__exp(-x))}
    
    #test whether an object is a DDF::RowVector or DDF::ColVector
    def self.is_vector?(v)
        return v.is_a?(DDF::ColVector) || v.is_a?(DDF::RowVector) || v.is_a?(Array)
    end

    def self.sigmoid(x)
        (x.is_a? Numeric) ? SIGMOID[x, 0] : x.to_v.each_with_operator(0, SIGMOID)
    end

    def self.dsigmoid(x)
        s = Math.sigmoid(x)
        return s * (1-s)
    end

    #f(x) = x
    def self.identify(x)
        x
    end

    def self.didentify(x) 
        x.class[*[1.0] * x.size]
    end

    def self.softmax(x)
        if !Math.is_vector?(x)
            raise ArgumentError, "Math.softmax, argument should be a vector"
        end
        v = x.class.new(x.size)
        sum = 0.0
        x.size.times {|i| sum += Math.__exp(x[i])}
        x.size.times {|i| v[i] = Math.__exp(x[i]) / sum}
        return v
    end

    SOFTPLUS = lambda {|x, _| Math.__log(1 + Math.__exp(x))}
    def self.softplus(x)
        return (x.is_a?(Numeric)) ? SOFTPLUS[x] : x.to_v.each_with_operator(0, SOFTPLUS) 
    end
    def self.dsoftplus(x)
        return Math.sigmoid(x)
    end

    RELU = lambda {|x, _| x > 0 ? x : 0}
    def self.relu(x)
        return (x.is_a(Numeric)) ? RELU[x] : x.to_v.each_with_operator(0, RELU)
    end

    def self.dtanh(x)
        return (x.is_a?(Numeric)) ? Math.__tanh(x) : x.to_v.each_with_operator(0, lambda {|x, _| v = Math.__tanh(x); 1 - v*v})
    end
end

module DDF 
        # Mathematical function
    class ActivationFunction 
        #the function itself      
        attr_reader :func  
    
        #the differential function
        attr_reader :diff_func
            
        def initialize(_func, _diff_func)
            @func = _func
            @diff_func = _diff_func
        end
    end

    ACT_SIGMOID = ActivationFunction.new(Math.method(:sigmoid), Math.method(:dsigmoid))
    ACT_NONE = ActivationFunction.new(Math.method(:identify), Math.method(:didentify))
    ACT_TANH = ActivationFunction.new(Math.method(:tanh), Math.method(:dtanh))
    ACT_SOFTPLUS = ActivationFunction.new(Math.method(:softplus), Math.method(:dsoftplus))
end