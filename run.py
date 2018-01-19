import numpy as np
import networkx as nx
import time
import matplotlib.pyplot as plt
import argparse
import operator
import tcd

from networkx.algorithms import community
from sklearn.metrics.cluster import normalized_mutual_info_score as nmi_score
from sklearn.metrics.cluster import v_measure_score as v_score

parser = argparse.ArgumentParser(description='Run a community detection algorithm on a dataset.')
parser.add_argument('fnl', nargs='?', type=int, default=1)
parser.add_argument('-g', '--graph', nargs=1)
parser.add_argument('-t', '--ground_truth', nargs=1)
args = parser.parse_args()

#the labels of the nodes have to be consicutive positive integers 
first_node_label = args.fnl

#dataset properties
graph_file = args.graph[0]
ground_truth_file = args.ground_truth[0]

print("#####################################################")
print("Loading Graph...")
start = time.time()
fh=open(graph_file, 'rb')
G=nx.read_edgelist(fh, nodetype=int)
fh.close()
end = time.time()
print("Graph loaded in %d s ." % (end - start))

nx.set_edge_attributes(G, 1, 'weight')
nx.set_node_attributes(G, None, 'cluster_id')

print ("Start community detection algorithm...")
start = time.time()
clusters_dic = tcd.community_detection(G, 2.1, 0.95, 3)
end = time.time()
print ("Clustering is finished in %d s ." % (end - start))

#initializing the array of cluster labels for the nodes
# node_cluster_labels = [0]*G.number_of_nodes()

node_cluster_labels = nx.get_node_attributes(G, 'cluster_id')
node_cluster_labels = sorted(node_cluster_labels.items(), key=operator.itemgetter(0))
node_cluster_labels = [x[1] for x in node_cluster_labels]
#node_cluster_labels = list(node_cluster_labels.values())
print(node_cluster_labels)

#setting the labels for node_cluster_labels
#the cluster label number strats from 1
# for i in range(len(top_level_communities)): 
# 	for j in top_level_communities[i]:
# 		node_cluster_labels[j-first_node_label] = i + 1

ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
nodes_class_labels = ground_truth[:,1]

print("NMI Score:\t%.2f" % nmi_score(nodes_class_labels, node_cluster_labels))
print("V Score:\t%.2f" % v_score(nodes_class_labels, node_cluster_labels))
print("Cluster#:\t%d" % len(clusters_dic))
print("#####################################################")

