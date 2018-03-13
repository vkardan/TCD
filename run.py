import numpy as np
import community
import networkx as nx
import time
import argparse
import operator
import pickle
import os

from networkx.algorithms import community as com
from sklearn.metrics.cluster import normalized_mutual_info_score as nmi_score
from sklearn.metrics.cluster import v_measure_score as v_score

import tools
import tcd_tools
import objective_functions as objf
#########################################################################################################################



#########################################################################################################################

parser = argparse.ArgumentParser(description='Run a community detection algorithm on a dataset.')
parser.add_argument('fnl', nargs='?', type=int, default=1)
parser.add_argument('-dp', '--dataset_path', nargs=1)
parser.add_argument('-dn', '--dataset_name', nargs=1)
parser.add_argument('--feed', nargs=1)
parser.add_argument('-m', '--method', nargs=1, type=str, default=None)
parser.add_argument('-e', '--epsilon', nargs=1, type=float, default=[2])
parser.add_argument('-b', '--beta', nargs=1, type=float, default=[0.5])
parser.add_argument('-a', '--alpha', nargs=1, type=int, default=[3])
parser.add_argument('-k', nargs=1, type=int, default=[2])
parser.add_argument('-r', '--repeat', nargs=1, type=int, default=[1])

parser.add_argument('--draw', action='store_true')
parser.add_argument('-s', '--search', action='store_true')
parser.add_argument('-cp', '--creat_pickle_file', action='store_true')
parser.add_argument('-up', '--use_pickle_file', action='store_true')
args = parser.parse_args()

#the labels of the nodes have to be consicutive positive integers 
first_node_label = args.fnl

#dataset properties
working_path = args.dataset_path[0]
dataset_name = args.dataset_name[0]
graph_file = working_path +'/'+dataset_name+'.txt'
ground_truth_file = working_path +'/'+dataset_name+'.clu'
pickle_file = working_path +'/'+dataset_name+'.pickle'

print("####################################################")
print("Loading Graph ... ", end='')
start = time.time()
fh=open(graph_file, 'rb')
graph = nx.read_edgelist(fh, nodetype=int, delimiter=' ')
fh.close()
end = time.time()
print("finished in %d s ." % (end - start))

#nx.set_node_attributes(graph, nx.current_flow_closeness_centrality(graph), 'weight')
#nx.set_edge_attributes(graph, 1, 'weight')
#for e in graph.edges:
#	graph[e[0]][e[1]]['weight'] = tcd_tools.calc_edge_weight(graph, e[0], e[1])
#	if graph[e[0]][e[1]]['weight'] != 0:
#		print("[{}, {}]: {}, {}".format(e[0], e[1], 1.0/graph[e[0]][e[1]]['weight'], 1.0/graph[e[1]][e[0]]['weight']))
#	else: print("[{}, {}]: {}, {}".format(e[0], e[1], "Inf", "Inf"))
node_count = graph.number_of_nodes()

ground_truth = np.loadtxt(ground_truth_file, dtype='int')
nodes_class_labels = ground_truth[:,1]

clusters_list = []
repeat = 0
ac, ah, av, anmi, anc = 0.0, 0.0, 0.0, 0.0, 0.0
sdc, sdh, sdv, sdnmi, sdnc = 0.0, 0.0, 0.0, 0.0, 0.0
if args.method != None:
	repeat = args.repeat[0]
	b_objf_value = -1
	for r in range(repeat):
		if args.method[0] == 'tcd':
			bp_list = []
			if args.search == True:
				bp_list = tcd_tools.parameter_selection(graph)
				for params in bp_list:
					clusters_list = tools.community_detection_wrapper(tcd_tools.tcd, graph, params[0], params[1], params[2])
			else:
#				bp_list.append((args.alpha[0], args.beta[0], args.epsilon[0]))
				can_clusters_list = tools.community_detection_wrapper(tcd_tools.tcd, graph, args.alpha[0], args.beta[0], args.epsilon[0])
				cluster_count = len(can_clusters_list)
				node_cluster_labels_dic = nx.get_node_attributes(graph, 'cluster_id')
				obj_value = objf.obj_function(graph, can_clusters_list, node_cluster_labels_dic, cluster_count, args.epsilon[0], args.beta[0], args.alpha[0])
				if  obj_value > b_objf_value:
					b_objf_value = obj_value
					clusters_list = can_clusters_list
				
			
		else: 	
			if args.method[0] == 'sslpa':	
				clusters_list = list(tools.community_detection_wrapper(tools.sslpa, graph))
			elif args.method[0] == 'afa':
				clusters_list = list(tools.community_detection_wrapper(tools.afa, graph, args.k[0] ))
			elif args.method[0] == 'gn':
				clusters_list = list(tools.community_detection_wrapper(tools.gn, graph))
			#Not working properly!!!
			elif args.method[0] == 'louvain':
				clusters_list = list(tools.community_detection_wrapper(tools.louvain, graph))

#		print(clusters_list)
#		for v in graph.nodes:
#			print("{}, ".format(graph.nodes[v]['cluster_id']), end='')
		eval_measures = tools.evaluation(nodes_class_labels, clusters_list, node_count, first_node_label)
		if args.method[0] != 'tcd':
			(ac, ah, av, anmi, anc) = map(operator.add, (ac, ah, av, anmi, anc), eval_measures)
			(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.add, (sdc, sdh, sdv, sdnmi, sdnc), map(operator.mul, eval_measures, eval_measures))
		else:
			(ac, ah, av, anmi, anc) = map(operator.mul, eval_measures, [repeat]*5)
			(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.mul, [repeat]*5, map(operator.mul, eval_measures, eval_measures))		
		print("####################################################")
else:
	directory_str = args.feed[0]
	directory = os.fsencode(directory_str)

	for f in os.listdir(directory):
		filename = os.fsdecode(f)
		if filename.endswith(".clu"): 
			repeat += 1
			clusters = np.loadtxt(str(os.path.join(directory_str, filename)), delimiter=' ')
			if first_node_label > 0 and clusters[0][0] == 0:
				clusters = clusters[1:]
			clusters_dic = {}
			for t in clusters:
				key = int(t[1])
				value = int(t[0])
				if key in clusters_dic:
					clusters_dic[key].append(value)
				else:
					clusters_dic[key] = [value]
			clusters_list = list(clusters_dic.values())
		eval_measures = tools.evaluation(nodes_class_labels, clusters_list, node_count, first_node_label)
		(ac, ah, av, anmi, anc) = map(operator.add, (ac, ah, av, anmi, anc), eval_measures)
		(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.add, (sdc, sdh, sdv, sdnmi, sdnc), map(operator.mul, eval_measures, eval_measures))
		print("####################################################")
print("################# Average Measures #################")
print("####################################################")
(ac, ah, av, anmi, anc, sdc, sdh, sdv, sdnmi, sdnc) = map(operator.truediv, (ac, ah, av, anmi, anc, sdc, sdh, sdv, sdnmi, sdnc), [repeat]*10)
(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.sub, (sdc, sdh, sdv, sdnmi, sdnc), map(operator.mul, (ac, ah, av, anmi, anc), (ac, ah, av, anmi, anc)) )
(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.abs, (sdc, sdh, sdv, sdnmi, sdnc))
(sdc, sdh, sdv, sdnmi, sdnc) = map(operator.pow, (sdc, sdh, sdv, sdnmi, sdnc), [0.5]*5)
(ac, ah, av, anmi, anc, sdc, sdh, sdv, sdnmi, sdnc) = map( lambda x: round(x, 2), (ac, ah, av, anmi, anc, sdc, sdh, sdv, sdnmi, sdnc))
tools.print_eval_result(ac, ah, av, anmi, anc)
print("####################################################")
print("################ Standard Deviation ################")
print("####################################################")
tools.print_eval_result(sdc, sdh, sdv, sdnmi, sdnc)
print("####################################################")

if args.draw == True:
	if args.use_pickle_file == True:	
		with open(pickle_file, 'rb') as handle:
			pos = pickle.load(handle)
	else:
		pos = nx.spring_layout(graph, iterations=50)
		if args.creat_pickle_file == True:
			with open(pickle_file, 'wb') as f:
				pickle.dump(pos, f)

	tools.draw_network( graph, clusters_list, ground_truth, pos )



