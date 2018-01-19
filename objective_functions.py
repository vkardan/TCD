import community as cm
import networkx as nx

def obj_function(graph, node_clusters_dic, cluster_count, epsilon, beta, alpha, amin=3, amax=17, bmin=0.25, bmax=0.95, emin=3, emax=5, etha=0.5):
	node_count = graph.number_of_nodes()

	gamma = node_count/10.0
	n_csize = min_max_norm(cluster_count, 1, node_count)
	n_epsilon = min_max_norm(epsilon, emin, emax)
	n_beta = min_max_norm(beta, bmin, bmax)
	n_alpha = min_max_norm(alpha, amin, amax)

	reg_term = (gamma*n_csize + n_epsilon + n_beta + n_alpha)/(gamma + 3)
	modularity = cm.modularity(node_clusters_dic, graph)

	return etha*modularity + (1 - etha)*reg_term

def min_max_norm(value, minv, maxv):
	return float(value - minv)/(maxv - minv)
