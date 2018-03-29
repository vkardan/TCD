import community as cm
import networkx as nx
import collections

def obj_function(graph, partition, node_clusters_dic, cluster_count, epsilon, beta, alpha, amin=3, amax=17, bmin=0.25, bmax=0.95, emin=3, emax=5, etha=0.5):
	node_count = graph.number_of_nodes()

	gamma = 0.0
	n_csize = min_max_norm(cluster_count, 2, node_count/2)
	n_epsilon = min_max_norm(epsilon, emin, emax)
	n_beta = min_max_norm(beta, bmin, bmax)
	n_alpha = min_max_norm(alpha, amin, amax)

	reg_term = (gamma*n_csize + n_epsilon + n_beta + n_alpha)/(gamma + 3)
	modularity = cm.modularity(node_clusters_dic, graph)

	coverage = nx.algorithms.community.quality.coverage(graph, partition)

	if modularity <= 0 or coverage <= 0: return 0.0
	return (1-etha)*coverage + etha*modularity

def min_max_norm(value, minv, maxv):
	return float(value - minv)/(maxv - minv)

def partial_density(graph):
	seen, visited, queue, weight, cluster_counter = set([]), set([]), collections.deque([]), 0.0, 0
	for root in list(graph.nodes()):
		if root not in visited :
			seen.add(root)
			queue.append(root)
			cluster_id = graph.nodes[root]['cluster_id']
			cluster_counter += 1
			mem_counter = 1
			par_weight = 0.0
			while queue :
				vertex = queue.popleft()
				for node in nx.all_neighbors(graph, vertex):
					if graph.nodes[node]['cluster_id'] == cluster_id and node not in visited:
						par_weight += graph[vertex][node]['weight']
						if node not in seen:	
							seen.add(node)
							queue.append(node)
							mem_counter += 1
				visited.add(vertex)
			if mem_counter > 1 :
				weight += 2*par_weight/(mem_counter*(mem_counter-1))
			else:
				weight += 1
	return weight/cluster_counter






