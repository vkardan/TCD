import networkx as nx
import collections
import operator

def community_detection(graph, epsilon, beta, alpha):
	sorted_nodes = sort_nodes_based_on_degrees(graph)
	clusters_dic = {}
	for selected_node_id in sorted_nodes :
		if graph.nodes[selected_node_id]['cluster_id'] == None :
			tclass = get_tolerance_class(graph, selected_node_id, epsilon)
			new_cluster = []
			for node_id in tclass :
				if graph.nodes[node_id]['cluster_id'] == None :
					new_cluster.append(node_id)
			close_cluster_ids = get_close_cluster_ids(clusters_dic, tclass, beta)
			temp = []
			for cluster_id in close_cluster_ids :
				temp = temp + clusters_dic[cluster_id]
				del clusters_dic[cluster_id]
			new_cluster = union(new_cluster, temp)
			new_cluster_id = new_cluster[0]
			clusters_dic[new_cluster_id] = new_cluster
			for node_id in new_cluster :
				graph.nodes[node_id]['cluster_id'] = new_cluster_id

	for cid, cluster in list(clusters_dic.items()) :
		if len(cluster) < alpha :
			nearest_cid = find_nearest_cluster_id(graph, cluster, epsilon)
			clusters_dic[nearest_cid] = clusters_dic[nearest_cid] + cluster
			for node_id in cluster :
				graph.nodes[node_id]['cluster_id'] = nearest_cid
			del clusters_dic[cid]
		
	return clusters_dic

def sort_nodes_based_on_degrees(graph):
	res = list(nx.degree(graph))
	res.sort(key=operator.itemgetter(1))
	return [x[0] for x in res]
	
def get_tolerance_class(graph, start_node, epsilon):
	root, tclass, selected_index = start_node, [], 0
	while True :
		neighborhood = bfs(graph, root, epsilon)
		if selected_index != 0 :
			tclass = intersection(tclass, neighborhood)
		else :
			tclass = neighborhood
		if selected_index < len(tclass)-1 :
			selected_index += 1
			root = tclass[selected_index]
		else:
			break
	return tclass	

def get_close_cluster_ids(clusters_dic, tclass, beta):
	res = []
	for cluster_id, cluster in list(clusters_dic.items()) :
		if calc_closeness(tclass, cluster) > beta :
			res.append(cluster_id)
	return res		 

def find_nearest_cluster_id(graph, cluster, epsilon):
	chosen_id = None
	counter = dict([(chosen_id, 0)])
	original_cluster_id = graph.nodes[cluster[0]]['cluster_id']
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
	return chosen_id

def calc_closeness(set1, set2):
	nodes_in_common = 0.0
	for node in set1 :
		if  node in set2:
			nodes_in_common += 1.0
	return nodes_in_common/min(len(set1), len(set2))
	
def bfs(graph, root, epsilon):
	seen, queue, depth_queue = set([root]), collections.deque([root]), collections.deque([0])
	while queue :
		vertex = queue.popleft()
		depth = depth_queue.popleft()
		for node in nx.all_neighbors(graph, vertex):
			if node not in seen:
				future_depth = depth + graph[vertex][node]['weight']
				if future_depth < epsilon :
					seen.add(node)
					queue.append(node)
					depth_queue.append(future_depth)
	return list(seen)

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

