import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
import sklearn.metrics.cluster as metric
#from sklearn.metrics.cluster import normalized_mutual_info_score as nmi_score
#from sklearn.metrics.cluster import v_measure_score as v_score

def draw_network(graph, clusters_list):
	size = float(len(clusters_list))
	pos = nx.spring_layout(graph)
	cluster_colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 
				'tab:pink', 'tab:gray', 'tab:olive', 'tab:cyan', 'xkcd:light navy', 'xkcd:ivory', 'xkcd:light cyan']
	cluster_shapes = "so^>v<dph8"
	cc = 0
	for com in clusters_list :
		temp = nx.drawing.nx_pylab.draw_networkx_nodes(graph, pos, com, node_size = 175, node_color = cluster_colors[cc], linewidths = 0.75)
		temp.set_edgecolor('k')
		cc += 1
	nx.drawing.nx_pylab.draw_networkx_edges(graph, pos, alpha=0.5)
	nx.draw_networkx_labels(graph, pos, font_size=9, font_color='k', font_family = 'Latin Modern Roman Demi')

	plt.axis('off')
	plt.show()

def evaluation(ground_truth_file, node_cluster_labels):
	ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
	nodes_class_labels = ground_truth[:,1]

	c = metric.completeness_score(nodes_class_labels, node_cluster_labels)
	h = metric.homogeneity_score(nodes_class_labels, node_cluster_labels)
	v = metric.v_measure_score(nodes_class_labels, node_cluster_labels)
	nmi = metric.normalized_mutual_info_score(nodes_class_labels, node_cluster_labels)
	print("c Score:\t%.3f" % c)
	print("h Score:\t%.3f" % h)
	print("V Score:\t%.3f" % v)
	print("NMI Score:\t%.3f" % nmi)

	return {'c':c, 'h':h, 'v':v, 'nmi':nmi}
