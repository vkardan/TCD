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
parser.add_argument('-k', nargs=1, type=int, default=2)
parser.add_argument('-r', '--repeat', nargs=1, type=int, default=1)
args = parser.parse_args()

#the labels of the nodes have to be consicutive positive integers 
first_node_label = args.fnl

#dataset properties
graph_file = args.graph[0]
ground_truth_file = args.ground_truth[0]

print("####################################################")
print("Loading Graph ... ", end='')
start = time.time()
fh=open(graph_file, 'rb')
graph = nx.read_edgelist(fh, nodetype=int)
fh.close()
end = time.time()
print("finished in %d s ." % (end - start))

nx.set_edge_attributes(graph, 1, 'weight')
node_count = graph.number_of_nodes()
ground_truth = np.loadtxt(ground_truth_file, delimiter=' ', dtype='int')
nodes_class_labels = ground_truth[:,1]

clusters_list = [] 
ac, ah, av, anmi, nc = 0.0, 0.0, 0.0, 0.0, 0.0

for r in range(args.repeat[0]):
	if args.method[0] == 'tcd':
		bp_list = []
		if args.search == True:
			bp_list = tcd_tools.parameter_selection(graph)
		else:
			bp_list.append((args.alpha[0], args.beta[0], args.epsilon[0]))
		for params in bp_list:
			clusters_list = tools.community_detection_wrapper(tcd_tools.tcd, graph, params[0], params[1], params[2])
		
	else: 	
		if args.method[0] == 'sslpa':	
			clusters_list = list(tools.community_detection_wrapper(tools.sslpa, graph))
		elif args.method[0] == 'afa':
			clusters_list = list(tools.community_detection_wrapper(tools.afa, graph, args.k[0] ))

	(ac, ah, av, anmi, nc) = map(operator.add, (ac, ah, av, anmi, nc), tools.evaluation(nodes_class_labels, clusters_list, node_count, first_node_label))
	print("####################################################")
print("################# Average Measures #################")
print("####################################################")
(ac, ah, av, anmi, nc) = map(operator.truediv, (ac, ah, av, anmi, nc), [args.repeat[0]]*5)
tools.print_eval_result(ac, ah, av, anmi, nc)
print("####################################################")

tools.draw_network( graph, clusters_list )



