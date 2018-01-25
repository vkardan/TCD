import numpy as np
import community
import networkx as nx
import time
import argparse
import operator

from networkx.algorithms import community as com
from sklearn.metrics.cluster import normalized_mutual_info_score as nmi_score
from sklearn.metrics.cluster import v_measure_score as v_score

import tools
import tcd_tools

#########################################################################################################################



##########################################################################################################################################

parser = argparse.ArgumentParser(description='Run a community detection algorithm on a dataset.')
parser.add_argument('fnl', nargs='?', type=int, default=1)
parser.add_argument('-g', '--graph', nargs=1)
parser.add_argument('-t', '--ground_truth', nargs=1)
parser.add_argument('-m', '--method', nargs=1, type=str, default='tcd')
parser.add_argument('-s', '--search', action='store_true')
parser.add_argument('-e', '--epsilon', nargs=1, type=int, default=2)
parser.add_argument('-b', '--beta', nargs=1, type=float, default=0.5)
parser.add_argument('-a', '--alpha', nargs=1, type=int, default=3)
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
graph = nx.read_edgelist(fh, nodetype=int)
fh.close()
end = time.time()
print("finished in %d s ." % (end - start))

nx.set_edge_attributes(graph, 1, 'weight')

ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
nodes_class_labels = ground_truth[:,1]

clusters_list = []

if args.method[0] == 'tcd':
	bp_list = []
	if args.search == True:
		bp_list = tcd_tools.parameter_selection(graph)
	else:
		bp_list.append((args.alpha[0], args.beta[0], args.epsilon[0]))
	for params in bp_list:
		clusters_list = tools.community_detection_wrapper(tcd_tools.tcd, graph, params[0], params[1], params[2])
		node_cluster_labels_dic = nx.get_node_attributes(graph, 'cluster_id')
		node_cluster_labels = sorted(node_cluster_labels_dic.items(), key=operator.itemgetter(0))
		node_cluster_labels = [x[1] for x in node_cluster_labels]
		tools.evaluation(nodes_class_labels, node_cluster_labels, len(clusters_list))
	
else: 	
	if args.method[0] == 'sslpa':	
		clusters_list = list(tools.community_detection_wrapper(tools.sslpa, graph))
	elif args.method[0] == 'afa':
		clusters_list = list(tools.community_detection_wrapper(tools.afa, graph, (3) ))

	cluster_count = len(clusters_list)

	#initializing the array of cluster labels for the nodes
	node_cluster_labels = [0]*graph.number_of_nodes()
	for i in range(cluster_count): 
		for j in clusters_list[i]:
			node_cluster_labels[j-first_node_label] = i + 1
	tools.evaluation(nodes_class_labels, node_cluster_labels, cluster_count)

tools.draw_network( graph, list( clusters_list ) )



