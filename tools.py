import numpy as np
import time
import networkx as nx
import matplotlib.pyplot as plt
import sklearn.metrics.cluster as metric

from networkx.algorithms import community as com

#TODO shape of nodes should be based on ground truth
def draw_network(graph, clusters_list, node_classes, pos):
	size = float(len(clusters_list))
	cluster_colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 
				'tab:pink', 'tab:gray', 'tab:olive', 'tab:cyan', 'xkcd:light navy', 'xkcd:ivory', 'xkcd:light cyan']
	cluster_shapes = "so^>v<dph8"
	cc = 0
	for com in clusters_list :
		for node in com :
			temp = nx.drawing.nx_pylab.draw_networkx_nodes(graph, pos, [node], node_size = 175, 
				node_color = cluster_colors[cc], linewidths = 0.75,  node_shape = 'o')
			temp.set_edgecolor('k')
		cc += 1
	nx.drawing.nx_pylab.draw_networkx_edges(graph, pos, alpha=0.5)
	nx.draw_networkx_labels(graph, pos, font_size=9, font_color='k', font_family = 'Latin Modern Roman Demi')

	plt.axis('off')
	plt.show()

def evaluation(nodes_class_labels, clusters_list, node_count, first_node_label, p=2):

	#initializing the array of cluster labels for the nodes
	node_cluster_labels = [0]*node_count
	for i in range(len(clusters_list)): 
		for j in clusters_list[i]:
			node_cluster_labels[j-first_node_label] = i + 1

	c = round(metric.completeness_score(nodes_class_labels, node_cluster_labels), p)
	h = round(metric.homogeneity_score(nodes_class_labels, node_cluster_labels), p)
	v = round(metric.v_measure_score(nodes_class_labels, node_cluster_labels), p)
	nmi = round(metric.normalized_mutual_info_score(nodes_class_labels, node_cluster_labels), p)
	nc = len(clusters_list)
	print_eval_result(c, h, v, nmi, nc)
	return (c, h, v, nmi, nc)

def community_detection_wrapper(algo_name, graph, *params):
	print ("Start %s%s Algorithm ... " % ((algo_name.__name__).upper(), str(params)), end='')
	start = time.time()
	res = algo_name(graph, *params)
	end = time.time()
	print ("finished in %d s ." % (end - start))
	
	return res 

def afa(graph, k): return list(com.asyn_fluidc(graph, k))


def sslpa(graph): return list(com.label_propagation.label_propagation_communities(graph))

def print_eval_result(c, h, v, nmi, nc): print("c Score:\t{}\nh Score:\t{}\nV Score:\t{}\nNMI Score:\t{}\nCluster#:\t{}".format(c, h, v, nmi, nc))



