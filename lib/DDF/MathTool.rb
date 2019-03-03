require 'matrix'

module DDF
    # Patch to class Array, add 'to_v' method
    class ::Array 
        # to_v, convert an array to a vector is possible. parameter 'is_row_vector' indicates whether convert to a row vector.
        def to_v
            Vector.[](*(self.map &to_f))
        end
    end

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

    # Mathematical function
    class Function 
        #the function itself
        attr_reader :func  

        #the differential function
        attr_reader :diff_func
        
        def initialize(_func, _diff_func)
            @func = _func
            @diff_func = _diff_func
        end
    end

    class << self
        
    end
end