require 'DeepDarkFantasy'

#make train data
DATA_SIZE = 20
x_data = DDF::Matrix.new(DATA_SIZE, 2)  #DATA_SIZE samples, each sample contains 1 features. 
y_data = DDF::Matrix.new(DATA_SIZE, 1)
DATA_SIZE.times {|i| 
    x_data.data[i][0] = 1.0
    x_data.data[i][1] = rand()
    y_data.data[i][0] = x_data.data[i][1] * 2.5 + 3.7 + (rand() - 0.5) / 3 #y = 2.5x + 3.7 (+ noise)
}  

#train
#Linear regression model: h(x) = \theta_0 + \theta_1 * x_1
theta = DDF::ColVector[rand(), rand()] #parameters of linear regression model, set a random start position.
rate = 0.3   #learning rate
x_data_t = x_data.transpose
5000.times { #train 5000 times
    #calc loss
    predict = (x_data * theta).as_vector   #A 100 x 1 ColVector
    diff = predict - y_data                
    loss = Math.sigmoid((diff * diff).sum / 2.0)  
    gradient = (x_data_t * diff).as_vector * Math.dsigmoid(loss)
    theta -= rate * gradient              
}

puts "Linear Regression Result : y = #{theta[1]}x #{theta[0] > 0 ? '+' : '-'} #{theta[0]}"

