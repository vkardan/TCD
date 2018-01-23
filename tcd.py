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


#########################################################################################################################

def run_tcd(graph, nodes_class_labels, alpha, beta, epsilon):
	nx.set_node_attributes(G, None, 'cluster_id')
	print ("Detecting communities with best parameters (a, b, e) as (%d, %.2f, %d)... " % (alpha, beta, epsilon), end='')
	start = time.time()
	clusters_dic = tcd_tools.community_detection(G, epsilon, beta, alpha)
	end = time.time()
	print ("finished in %d s ." % (end - start))

	node_cluster_labels_dic = nx.get_node_attributes(G, 'cluster_id')
	node_cluster_labels = sorted(node_cluster_labels_dic.items(), key=operator.itemgetter(0))
	node_cluster_labels = [x[1] for x in node_cluster_labels]
	#print(node_cluster_labels)

	print("Modularity Score:\t%.2f" % community.modularity(node_cluster_labels_dic, G))
	print("NMI Score:\t%.2f" % nmi_score(nodes_class_labels, node_cluster_labels))
	print("V Score:\t%.2f" % v_score(nodes_class_labels, node_cluster_labels))
	print("Cluster#:\t%d" % len(clusters_dic))
	print("#####################################################")

	return clusters_dic

def parameter_selection(G):
	print("Start Searching for the best clustering:")
	g_start = time.time()
	b_obj_val, b_alpha, b_beta, b_epsilon = 0, None, None, None
	clusters_dic = {}
	node_cluster_labels_dic = {}
	bp_list = []
	for epsilon in range(2, 6):
		for alpha in range(3, 15):
			for b in range(5, 20):
				beta = b/20.0
				nx.set_node_attributes(G, None, 'cluster_id')

				print ("Detecting communities with (a, b, e) as (%d, %.2f, %d)... " % (alpha, beta, epsilon), end='')
				start = time.time()
				clusters_dic = tcd_tools.community_detection(G, epsilon, beta, alpha)
				end = time.time()
				print ("finished in %d s ." % (end - start))

				print ("Estimating the quality of clusters ..." , end='')			
				cluster_count = len(clusters_dic)
				node_cluster_labels_dic = nx.get_node_attributes(G, 'cluster_id')
				
				obj_val = objf.obj_function(G, list(clusters_dic.values()), node_cluster_labels_dic, cluster_count, epsilon, beta, alpha)
				print(obj_val)
				if obj_val > b_obj_val :
					b_obj_val, b_alpha, b_beta, b_epsilon = obj_val, alpha, beta, epsilon
					bp_list = [(alpha, beta, epsilon)]
				elif obj_val == b_obj_val :
					bp_list.append((alpha, beta, epsilon))
					
				print ("finished in %d s ." % (end - start))

	g_end = time.time()
	print("Search is finished in %d s ." % (g_end - g_start))
	print("Best parameters: \ne:\t%d\nb:\t%.2f\na:\t%d" % (b_epsilon, b_beta, b_alpha) )
	print("#####################################################")

	return bp_list

def draw_network(graph, clusters_dic):
	size = float(len(clusters_dic))
	pos = nx.spring_layout(graph)
	cluster_colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 
				'tab:pink', 'tab:gray', 'tab:olive', 'tab:cyan', 'xkcd:light navy', 'xkcd:ivory', 'xkcd:light cyan']
	cluster_shapes = "so^>v<dph8"
	cc = 0
	for key, com in clusters_dic.items() :
		nx.drawing.nx_pylab.draw_networkx_nodes(graph, pos, com, node_size = 40, node_color = cluster_colors[cc])
		cc += 1
	nx.drawing.nx_pylab.draw_networkx_edges(graph, pos, alpha=0.5)
	plt.show()

##########################################################################################################################################

parser = argparse.ArgumentParser(description='Run a community detection algorithm on a dataset.')
parser.add_argument('fnl', nargs='?', type=int, default=1)
parser.add_argument('-g', '--graph', nargs=1)
parser.add_argument('-t', '--ground_truth', nargs=1)
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
G=nx.read_edgelist(fh, nodetype=int)
fh.close()
end = time.time()
print("finished in %d s ." % (end - start))

nx.set_edge_attributes(G, 1, 'weight')

bp_list = []
if args.search == True:
	bp_list = parameter_selection(G)
else:
	bp_list.append((args.alpha[0], args.beta[0], args.epsilon[0]))

ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
nodes_class_labels = ground_truth[:,1]
clusters_dic = {}
for params in bp_list:
	clusters_dic = run_tcd(G, nodes_class_labels, params[0], params[1], params[2])

draw_network(G, clusters_dic)



