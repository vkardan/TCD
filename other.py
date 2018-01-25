import networkx as nx
import time
import argparse
import operator

from networkx.algorithms import community as com

import tools

#################################################################################################################

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

#nx.set_edge_attributes(G, 1, 'weight')
#nx.set_node_attributes(G, None, 'cluster_id')

print ("Start community detection algorithm...")
start = time.time()
clusters_list = list(com.asyn_fluidc(G, 3)) #list(com.label_propagation.label_propagation_communities(G))
end = time.time()
print ("Clustering is finished in %d s ." % (end - start))

#print(clusters_list)
#initializing the array of cluster labels for the nodes
node_cluster_labels = [0]*G.number_of_nodes()

#node_cluster_labels = nx.get_node_attributes(G, 'cluster_id')
#node_cluster_labels = sorted(node_cluster_labels.items(), key=operator.itemgetter(0))
#node_cluster_labels = [x[1] for x in node_cluster_labels]
#print(node_cluster_labels)

#setting the labels for node_cluster_labels
#the cluster label number strats from 1
for i in range(len(clusters_list)): 
	for j in clusters_list[i]:
		node_cluster_labels[j-first_node_label] = i + 1

tools.evaluation(ground_truth_file, node_cluster_labels)
print("Cluster#:\t%d" % len(clusters_list))
print("#####################################################")

#drawing
tools.draw_network(G, clusters_list)





