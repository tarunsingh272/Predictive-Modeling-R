#---------------------------------------------------------------#

library(neuralnet)
library(caTools)
library(mlbench)
library(caret)
library(e1071)

#---------------------------------------------------------------#

# load data

# read in csv files
churn.1 <- read.csv("file_path//churnTrain.csv", header = TRUE, strip.white = TRUE)
churn.2 <- read.csv("file_path//churnTest.csv", header = TRUE, strip.white = TRUE)

#---------------------------------------------------------------#

# combine data
churn <- rbind(churn.1, churn.2)

# remove train and test splits from global environment
rm(churn.1, churn.2)

# reorder columns 
churn <- churn[c(20,1,3,4,5,2,6:19)]

# create vectors of column max and min Values
maxs <- apply(churn[,6:20], 2, max)
mins <- apply(churn[,6:20], 2, min)

# use scale() and convert the resulting matrix to a data frame
scaled.data <- as.data.frame(scale(churn[,6:20], center = mins, scale = maxs - mins))

#---------------------------------------------------------------#

# convert churn column from Yes/No to 1/0
churn.col <- as.numeric(churn$churn)-1
data <- cbind(churn.col, scaled.data)

# set random seed
set.seed(101)

# create split - you can choose any column 
split <- sample.split(data$churn.col, SplitRatio = 0.70)

# cplit based off of split Boolean Vector
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

#---------------------------------------------------------------#

# grab names for variables
features <- names(scaled.data)

# concatenate strings
nnet <- paste(features,collapse = ' + ')
nnet <- paste('churn.col ~' ,nnet)

# convert to formula
nnet <- as.formula(nnet)

# review form - this is how R takes output and input variables with most models
nnet

#---------------------------------------------------------------#

# build the neural network using training data ~ note hidden layer structure
nn <- neuralnet(nnet, train, hidden=c(5, 5, 5), linear.output=FALSE)

# compute predictions from test set
predicted.nn.values <- compute(nn, test[2:16])

# create data frame of node outputs and isolate individual probabilities
probs <- data.frame(predicted.nn.values)
probs$pred <- ifelse(probs$net.result > .5, 1, 0)

# grab prediction columns
probabilities <- subset(probs, select=c("net.result", "pred"))

# cbind predictions columns to test data
output.data <- cbind(test, probabilities)

# create match and prediction breakdown columns
output.data$match <- ifelse(output.data$churn.col == output.data$pred, "yes", "no")
output.data$`prediction breakdown` <- ifelse(output.data$churn.col == 1 & output.data$pred == 1, "true positive",
                                             ifelse(output.data$churn.col == 1 & output.data$pred == 0, "false negative",
                                                    ifelse(output.data$churn.col == 0 & output.data$pred == 1, "false positive",
                                                           "true negative")))
                                                                      
# reorganize columns
output.data <- output.data[c(1,18:20,17,2:16)]

# overall model accuracy and granular view - same as prediction breakdown column
model.accuracy <- sum(output.data$match == "yes") / nrow(output.data)
conf.mat <- confusionMatrix(test$churn.col, output.data$pred)
conf.mat

#---------------------------------------------------------------#

# visualize neural network 
plot(nn, arrow.length = .165, dimension = 20, show.weights = TRUE, fontsize = 6)

# end Neural Network Script
