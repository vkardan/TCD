import numpy as np
import community
import networkx as nx
import time
import matplotlib.pyplot as plt
import argparse
import operator
import tcd_tools
import objective_functions as objf

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
print("Loading Graph ... ", end='')
start = time.time()
fh=open(graph_file, 'rb')
G=nx.read_edgelist(fh, nodetype=int)
fh.close()
end = time.time()
print("finished in %d s ." % (end - start))

nx.set_edge_attributes(G, 1, 'weight')

print("Start Searching for the best clustering:")
g_start = time.time()
b_obj_val, b_alpha, b_beta, b_epsilon = 0, None, None, None
clusters_dic = {}
node_cluster_labels_dic = {}
for epsilon in range(2, 6):
	for alpha in range(3, 15):
		for b in range(5, 20):
			beta = b/20.0
			nx.set_node_attributes(G, None, 'cluster_id')

			print ("Detecting communities ... ", end='')
			start = time.time()
			clusters_dic = tcd_tools.community_detection(G, epsilon, beta, alpha)
			end = time.time()
			print ("finished in %d s ." % (end - start))

			print ("Estimating the quality of clusters ... ", end='')			
			cluster_count = len(clusters_dic)
			node_cluster_labels_dic = nx.get_node_attributes(G, 'cluster_id')
			obj_val = objf.obj_function(G, node_cluster_labels_dic, cluster_count, epsilon, beta, alpha)
			if obj_val > b_obj_val :
				b_obj_val, b_alpha, b_beta, b_epsilon = obj_val, alpha, beta, epsilon
			print ("finished in %d s ." % (end - start))

g_end = time.time()
print("Search is finished in %d s ." % (g_end - g_start))
print("Best parameters: \ne:\t%d\nb:\t%.2f\na:\t%d" % (b_epsilon, b_beta, b_alpha) )

node_cluster_labels = sorted(node_cluster_labels_dic.items(), key=operator.itemgetter(0))
node_cluster_labels = [x[1] for x in node_cluster_labels]
print(node_cluster_labels)

ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
nodes_class_labels = ground_truth[:,1]

print("Modularity Score:\t%.2f" % community.modularity(node_cluster_labels_dic, G))
print("NMI Score:\t%.2f" % nmi_score(nodes_class_labels, node_cluster_labels))
print("V Score:\t%.2f" % v_score(nodes_class_labels, node_cluster_labels))
print("Cluster#:\t%d" % len(clusters_dic))
print("#####################################################")


