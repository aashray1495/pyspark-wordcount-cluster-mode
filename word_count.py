import sys

from pyspark import SparkContext, SparkConf

if __name__ == "__main__":

  # create Spark context with Spark configuration
  conf = SparkConf().setAppName("Spark Count")
  sc = SparkContext(conf=conf)

  # # get threshold
  # threshold = int(sys.argv[2])

  # read in text file and split each document into words
  tokenized = sc.textFile('/opt/spark/python/input.txt').flatMap(lambda line: line.split(" "))

  # count the occurrence of each word
  wordCounts = tokenized.map(lambda word: (word, 1)).reduceByKey(lambda v1,v2:v1 +v2)

  # # filter out words with fewer than threshold occurrences
  # filtered = wordCounts.filter(lambda pair:pair[1] >= threshold)

  # count characters
  # charCounts = wordCounts.flatMap(lambda pair:pair[0]).map(lambda c: c).map(lambda c: (c, 1)).reduceByKey(lambda v1,v2:v1 +v2)

  list = wordCounts.collect()
  print (repr(list)[1:-1])
