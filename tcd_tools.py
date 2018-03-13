import networkx as nx
import collections
import operator
import time
import tools
import objective_functions as objf
import random

def parameter_selection(graph, repetition=10):
	print("Start Searching for the best clustering:")
	g_start = time.time()
	b_obj_val, b_alpha, b_beta, b_epsilon = 0, 0, 0, 0
	clusters_dic = {}
	node_cluster_labels_dic = {}
	bp_list = []
	
	for epsilon in range(2, 3):
		for alpha in range(3, 15):
			for b in range(10, 20):
				beta = b/20.0
				avg_obj_val = 0.0
				for rep in range(repetition):
					clusters_list = tools.community_detection_wrapper(tcd, graph, alpha, beta, epsilon)
				
#					print ("Estimating the quality of clusters ... " , end='')
#					start = time.time()					
					cluster_count = len(clusters_list)
					node_cluster_labels_dic = nx.get_node_attributes(graph, 'cluster_id')
					
					obj_val = objf.obj_function(graph, clusters_list, node_cluster_labels_dic, cluster_count, epsilon, beta, alpha)
					print ("Estimated Quality: {}".format(obj_val))
					avg_obj_val +=  obj_val
#					end = time.time()
#					print ("finished in %d s, O: %f" % ((end - start), obj_val))
				avg_obj_val /= repetition
				print ("Average Estimated Quality: {}".format(avg_obj_val))
				if avg_obj_val > b_obj_val :
					b_obj_val, b_alpha, b_beta, b_epsilon = avg_obj_val, alpha, beta, epsilon
					bp_list = [(alpha, beta, epsilon)]
				elif avg_obj_val == b_obj_val :
					bp_list.append((alpha, beta, epsilon))

	g_end = time.time()
	print("Search is finished in %d s ." % (g_end - g_start))
	print("Best parameters: \ne:\t%d\nb:\t%.2f\na:\t%d" % (b_epsilon, b_beta, b_alpha) )
	print("#####################################################")

	return bp_list

def tcd(graph, alpha, beta, epsilon):
	nx.set_node_attributes(graph, None, 'cluster_id')
	sorted_nodes = sort_nodes_based_on_degrees(graph)
	clusters_dic = {}
	for selected_node_id in sorted_nodes :
		if graph.nodes[selected_node_id]['cluster_id'] == None :
			tclass = get_tolerance_class(graph, selected_node_id, epsilon, sort_by_degree=True)
#			if selected_node_id == 17:
#				print("TC:", tclass)
			new_cluster = set([])
			for node_id in tclass :
				if graph.nodes[node_id]['cluster_id'] == None :
					new_cluster.add(node_id)
			close_cluster_ids = get_close_cluster_ids(clusters_dic, tclass, beta)
			temp = set([])
			for cluster_id in close_cluster_ids :
				temp = temp | clusters_dic[cluster_id]
				del clusters_dic[cluster_id]
			new_cluster = new_cluster | temp
			new_cluster_id = new_cluster.pop()
			new_cluster.add(new_cluster_id)
			clusters_dic[new_cluster_id] = new_cluster
			for node_id in new_cluster :
				graph.nodes[node_id]['cluster_id'] = new_cluster_id

	for cid in list(clusters_dic.keys()) :
		if len(clusters_dic[cid]) < alpha :
			nearest_cid = find_nearest_cluster_id(graph, clusters_dic[cid], cid, epsilon)				
			clusters_dic[nearest_cid] = clusters_dic[nearest_cid] | clusters_dic[cid]
			for node_id in clusters_dic[cid] :
				graph.nodes[node_id]['cluster_id'] = nearest_cid
			del clusters_dic[cid]		
	return list(clusters_dic.values())

def sort_nodes_based_on_degrees(graph, nbunch=None, desc=False):
	res = list(nx.degree(graph, nbunch))
	res.sort(key=operator.itemgetter(1), reverse=desc)
	return [x[0] for x in res]
	
def get_tolerance_class(graph, start_node, epsilon, sort_by_degree=False):
	tclass, root, next_index =set([start_node]), start_node, 1
	candidates = bfs(graph, root, epsilon)
	candidates.discard(root) 
	while candidates:
		root = random.choice(list(candidates)) #rondom selection
#		best_w = -1
#		for c in candidates:
#			w = graph.nodes[c]['weight']
#			if w > best_w or (w == best_w and random.randrange(0,1) == 1): 
#				root, best_w = c, w
		candidates.discard(root)
#		root = candidates.pop()
		tclass.add(root)
		neighborhood = bfs(graph, root, epsilon)
		candidates = candidates & neighborhood
#		if start_node == 17:
#			print("N{}:\t{}".format(root, neighborhood))
#			print("TC{}:\t{}".format(root, tclass))
	return tclass	

def get_close_cluster_ids(clusters_dic, tclass, beta):
	res = []
	for cluster_id, cluster in list(clusters_dic.items()) :
		if calc_closeness(tclass, cluster) > beta :
			res.append(cluster_id)
	return res		 

def find_nearest_cluster_id(graph, cluster, original_cluster_id, epsilon):
	chosen_id = None
	counter = dict([(chosen_id, 0)])
	for vertex in cluster :
		neighborhood = bfs(graph, vertex, epsilon)
		for node_id in neighborhood:
			cid = graph.nodes[node_id]['cluster_id']
			if cid != original_cluster_id :
				if cid in counter :				
					counter[cid] += 1
				else:
					counter[cid] = 1
				if counter[cid] > counter[chosen_id] :
					chosen_id = cid
	if chosen_id == None:
		for u in cluster:
			for v in nx.all_neighbors(graph, u):
				cid = graph.nodes[v]['cluster_id']
				if cid != original_cluster_id:
					chosen_id = cid
					break
			if chosen_id != None: break
	if chosen_id == None: chosen_id = original_cluster_id
	return chosen_id

def calc_closeness(set1, set2):
	return len(set1 & set2)/min(len(set1), len(set2))

def calc_edge_weight(graph, node1, node2):
	z = len(intersection(nx.all_neighbors(graph, node1), nx.all_neighbors(graph, node2)))
	k1 = nx.degree(graph, node1)
	k2 = nx.degree(graph, node2)
	return min(k1-1, k2-1)/(z+1.0)	

def bfs(graph, root, epsilon):
	seen, queue, distance = set([root]), collections.deque([root]), 1
	while queue :
		parent = queue.popleft()
		for child in nx.all_neighbors(graph, parent):
			if child not in seen:
				if distance < epsilon :
					seen.add(child)
					queue.append(child)
		distance += 1
	return seen

def bfs2(graph, root, epsilon):
	seen, queue, distance_dic = [root], collections.deque([root]), {root: 0.0}
	while queue :
		parent = queue.popleft()
		for child in nx.all_neighbors(graph, parent):
			weight = graph[parent][child]['weight']
			if weight != 0:
				distance = round(distance_dic[parent] + round(1.0/weight, 10), 10)
				if distance < epsilon :
					if child not in seen: 
						seen.append(child)
						queue.append(child)
						distance_dic[child] = distance
					elif distance < distance_dic[child]:
						if child not in queue: queue.append(child)
						distance_dic[child] = distance
	return seen

def union(set1, set2):
	res = set1	
	for node in set2 :
		if  node not in set1:
			res.append(node)
	return res

def intersection(set1, set2):
	res = []	
	for node in set1 :
		if  node in set2:
			res.append(node)
	return res



