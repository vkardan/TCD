# This class provides necessary methods for creating datasets. 
#
# @author: Vahid Kardan

class Dataset

	def initialize

	end

	def self.create_dataset_from_gml_file(input:, graph_path:, clusters_path:, directed: true, first_node_id: 1)
		n = 0
		m = 0
		index = first_node_id
		state = 0
		node = Hash.new
		edge = Hash.new
		graph = Hash.new
		fi = File.open(input, "r")
		fi.each_line do |line| 
			items = line.split(/\s/) - [""]
			case items[0]
			when 'node'
				state = 1
			when 'edge'
				state = 10
			when 'id'
				raise 'Bad id format!' if state != 1
				node['id'] = items[1].to_i
				graph[node['id']] = Hash.new
				graph[node['id']]['id'] = index
				state = 2
			when 'value'
				raise 'Bad value format!' if state != 2
				node['cluster'] = items[1].to_i + 1
				#clusters.puts node['id']+' '+node['cluster']
				graph[node['id']]['cluster'] = node['cluster']
				n += 1
				index += 1
				state = 3
			when 'source'
				raise 'Bad source format!' if state != 10 && state != 3
				if state == 10 then
					edge['source'] = items[1].to_i 
					state = 11
				else # state = 3
					state = 0 
				end
			when 'target'
				raise 'Bad target format!' if state != 11
				edge['target'] = items[1].to_i
				graph[edge['source']]['children'] ||= []
				graph[edge['source']]['children'] << graph[edge['target']]['id'] 
				m += 1
				unless directed then
					graph[edge['target']]['children'] ||= []
					graph[edge['target']]['children'] << graph[edge['source']]['id'] 
					m += 1
				end
				state = 0
			end						
		end
		puts graph.size
		graph = graph.sort.to_h
		File.open(clusters_path, 'w') do |c|
			graph.each do |s, h|
				raise "Bad format, no id found for node with source: #{s}" if h['id'].nil?
				raise "Bad format, no cluster found for node with source: #{s}" if h['cluster'].nil?
				c.puts "#{h['id']} #{h['cluster']}"
			end
		end
		File.open(graph_path, 'w') do |g|
			graph.each do |s, h|
				h['children'].sort.each { |child| g.puts "#{h['id']} #{child}" } unless h['children'].nil?
			end
		end
		File.open(graph_path+'.meta', 'w') {|f| f.puts "N: #{n}, M: #{m}"}
	end

	def self.create_dataset_from_paj_file(graph_input:, clusters_input:, graph_path:, clusters_path:, directed:, first_node_id: 1)
		n = 0
		m = 0
		index = first_node_id
		state = 0
		graph = Hash.new
		fi = File.open(graph_input, "r")
		fi.each_line do |line| 
			items = line.split(/\s/) - [""]
			case state
			when 0
				# raise "Bad PAJ file format, keyword '*vertices' was not found!" if items[0].downcase != '*vertices'
				next if items == [] || items[0].downcase != '*vertices'
				n = items[1].to_i
				state = 1
			when 1
				state = 10 if items[0].downcase == '*edges' || items[0].downcase == '*arcs'
				node_counter = index - first_node_id
				raise "Mismatch number of nodes: #{node_counter}, expected: #{n}!" unless (state == 1 && node_counter < n) || (state == 10 && node_counter == n) 
				next if state == 10 
				node_id = items[0].to_i
				graph[node_id] = {}
				graph[node_id]['id'] = index
				index += 1
			when 10
				source = items[0].to_i
				target = items[1].to_i
				graph[source]['children'] ||= []
				unless graph[source]['children'].include?(target) || source == target then
					graph[source]['children'] << target
					m += 1
				end
				unless directed then
					graph[target]['children'] ||= []
					unless graph[target]['children'].include?(source) || source == target then
						graph[target]['children'] << source
						m += 1
					end
				end
			end
		end
		node_id = 0
		cluster_id = nil
		fi = File.open(clusters_input, "r")
		fi.each_line do |line|
			items = line.split(/\s/) - [""]
			next if items == [] || items[0][0] == "*" || items[0][0] == "%" || items[0][0] == "#"
			if items[1].nil? then
				node_id += 1
				cluster_id = items[0].to_i
			else 
				node_id = items[0].to_i
				cluster_id = items[1].to_i
			end
			raise "Node with id: #{node_id} not found!" if graph[node_id].nil?
			graph[node_id]['cluster'] = cluster_id
		end
		puts graph.size
		graph = graph.sort.to_h
		File.open(clusters_path, 'w') do |c|
			graph.each do |s, h|
				raise "Bad format, no id found for node with source: #{s}" if h['id'].nil?
				raise "Bad format, no cluster found for node with source: #{s}" if h['cluster'].nil?
				c.puts "#{h['id']} #{h['cluster']}"
			end
		end
		File.open(graph_path, 'w') do |g|
			graph.each do |s, h|
				h['children'].sort.each { |child| g.puts "#{h['id']} #{child}" } unless h['children'].nil?
			end
		end
		File.open(graph_path+'.meta', 'w') {|f| f.puts "N: #{n}, M: #{m}"}
	end

	def self.create_dataset_from_cites_file(graph_input:, clusters_input:, graph_path:, clusters_path:, directed:, first_node_id: 1)
		m = 0
		index = first_node_id
		id_dic = Hash.new
		cluster_dic = Hash.new
		graph = Hash.new
		fi = File.open(clusters_input, "r")
		fi.each_line do |line|
			items = line.split(/\s/) - [""]
			id_dic[items[0]] = index
			graph[index] = {}
			cluster_label = items[-1].downcase
			cluster_dic[cluster_label] ||= cluster_dic.size + 1	
			graph[index]['cluster'] = cluster_dic[cluster_label]
			index += 1
		end

		fi = File.open(graph_input, "r")
		fi.each_line do |line| 
			items = line.split(/\s/) - [""]
			source = id_dic[items[0]]
			target = id_dic[items[1]]
			puts "Undefined source: #{items[0]}" if source.nil?
			puts "Undefined target: #{items[1]}" if target.nil?
			next if source.nil? || target.nil?
			graph[source]['children'] ||= []
			graph[source]['children'] << target
			m += 1
			unless directed then
				graph[target]['children'] ||= []
				graph[target]['children'] << source
				m += 1
			end
		end

		puts graph.size
		graph = graph.sort.to_h
		File.open(clusters_path, 'w') do |c|
			graph.each do |node, h|
				raise "Bad format, no cluster found for node: #{node}" if h['cluster'].nil?
				c.puts "#{node} #{h['cluster']}"
			end
		end
		File.open(graph_path, 'w') do |g|
			graph.each do |node, h|
				h['children'].sort.each { |child| g.puts "#{node} #{child}" } unless h['children'].nil?
			end
		end
		File.open(graph_path+'.meta', 'w') {|f| f.puts "N: #{graph.size}, M: #{m}, C: #{cluster_dic.size}"}
	end

	def evaluate(real_classes_path:, clusters_path:)
		graph = Hash.new
		c = Hash.new
		k = Hash.new
		File.open(real_classes_path, "r").each_line do |line|
			items = line.split(/\s/) - [""]
			next if items[0] == '#'
			node_id = items[0]
			node_class = items[1]
			graph[node_id] = {}
			graph[node_id]["c"] = node_class
			c[node_class] ||= []
			c[node_class] << node_id
		end
		d = 1
		alpha = -1
		beta = -1
		File.open(clusters_path, "r").each_line do |line|
			items = line.split(/\s/) - [""]
			next if items[0] == '#'
			if( items[0] == '*' ) then
				d = items[1]
				beta = items[2]
				alpha = items[3]
				next
			end
			node_id = items[0]
			node_cluster = items[1]
			graph[node_id]["k"] = node_cluster
			k[node_cluster] ||= []
			k[node_cluster] << node_id
		end

		a = create_contingency_table graph: graph, c: c.keys, k: k.keys
		vm = v_measure a: a, k: k.keys, c: c.keys, n: graph.size
		nmi = nmi_measure a: a, k: k.keys, c: c.keys, n: graph.size
		puts "V-measure: #{vm}, NMI: #{nmi}"
	end

private
	def objective_function(graph:, k:)

	end
	def create_contingency_table(graph:, c:, k:)
		a = Hash.new
		c.each do |i|
			a[i]=Hash.new
			k.each do |j|
				a[i][j] = 0
			end
		end
		graph.each do |node, h|
			a[h["c"]][h["k"]] += 1
		end
		return a
	end

	def nmi_measure(a:, k:, c:, n:)
		hk = h_k(a: a, k: k, c: c, n: n)
		hc = h_c(a: a, k: k, c: c, n: n)
		hkc = h_k_c(a: a, k: k, c: c, n: n)
		info = hk - hkc
#		puts "H(K): #{hk}, H(C): #{hc}, H(K|C): #{hkc}, I(C,K): #{info}"
		return info/Math::sqrt(hc*hk) if hc != 0.0 && hk != 0.0
		return info
	end

	def v_measure(a:, k:, c:, n:, beta: 1)
		h = homogeneity(a: a, k: k, c: c, n: n)
		c = completeness(a: a, k: k, c: c, n: n)
		puts "h: #{h}, c: #{c}"
		return (1+beta)*h*c/(beta*h+c)
	end

	def homogeneity(a:, k:, c:, n:)
		hc = h_c(a: a, k: k, c: c, n: n)
		return 1 - h_c_k(a: a, k: k, c: c, n: n)/hc if hc != 0.0
		return 1
	end

	def completeness(a:, k:, c:, n:)
		hk = h_k(a: a, k: k, c: c, n: n)
		return 1 - h_k_c(a: a, k: k, c: c, n: n)/hk if hk != 0.0
		return 1
	end

	def h_c_k(a:, k:, c:, n:) #H(C|K)
		result = 0.0
		k.each do |j|
			sum = 0.0
			c.each do |i|
				sum += a[i][j]
			end
			c.each do |i|
				result += a[i][j]*Math::log(a[i][j]/sum, 2) if a[i][j] != 0
			end
		end
		return -result/n
	end

	def h_k_c(a:, k:, c:, n:)
		result = 0.0
		c.each do |i|
			sum = 0.0
			k.each do |j|
				sum += a[i][j]
			end
			k.each do |j|
				result += a[i][j]*Math::log(a[i][j]/sum, 2) if a[i][j] != 0
			end
		end
		return -result/n
	end

	def h_c(a:, k:, c:, n:)
		result = 0.0
		c.each do |i|
			sum = 0.0
			k.each do |j|
				sum += a[i][j]
			end
			result += sum*Math::log(sum/n,2) if sum != 0.0	#Although sum must never be zero!		
		end
		return -result/n
	end

	def h_k(a:, k:, c:, n:)
		result = 0.0
		k.each do |j|
			sum = 0.0
			c.each do |i|
				sum += a[i][j]
			end
			result += sum*Math::log(sum/n,2) if sum != 0.0 #Although sum must never be zero!			
		end
		return -result/n
	end
end

def run(params)
 
	ground_truth_path = '../Dropbox/Vahid-Research/community-detection/datasets/'
	algo_path = 
		case params[0]
		when 'i' 
			'../Dropbox/Vahid-Research/community-detection/Infomap/output/'
		when 'l'
			'../Dropbox/Vahid-Research/community-detection/gen-louvain/output/'
		when 't'
			'../Dropbox/Vahid-Research/community-detection/TCD/output/'
		else
			puts 'Unknown algorithm!'
			return
		end

	dataset_name = 
		case params[1]
		when 'k'
			'karate'
		when 'p'
			'polblogs'
		when 'p2'
			'polblogs2'
		when 'co'
			'cora'
		when 'ci'
			'citeseer'
		when 'y'
			'yeast'
		when 'f'
			'football'
		else
			puts 'Unknown dataset!'
			return
		end	
#	Dir[algo_path+"#{dataset_name}/*"].each do |name|	
		Dataset.new.evaluate(
			real_classes_path: ground_truth_path+"#{dataset_name}/#{dataset_name}.clu", 
			clusters_path: algo_path+"#{dataset_name}.clu"
		)
#	end
end
# path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/polblogs/'
# Dataset.create_dataset_from_gml_file(
# 	input: path+'polblogs.gml', 
# 	graph_path: path+'polblogs.txt', 
# 	clusters_path: path+'polblogs.clu',
# 	first_node_id: 1
# )

# name = "football"
# path = "/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/#{name}/"
# Dataset.create_dataset_from_gml_file(
# 	input: path+name+'.gml', 
# 	graph_path: path+name+'.txt', 
# 	clusters_path: path+name+'.clu',
# 	directed: false,
# 	first_node_id: 1
# )

# path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/karate/'
# Dataset.create_dataset_from_paj_file(
# 	graph_input: path+'karate.paj', 
# 	clusters_input: path+'karate.paj.clu',
# 	graph_path: path+'karate.txt', 
# 	clusters_path: path+'karate.clu',
# 	directed: false,
# 	first_node_id: 1
# )

# name = "yeast"
# path = "/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/#{name}/"
# Dataset.create_dataset_from_paj_file(
# 	graph_input: path+name+".paj", 
# 	clusters_input: path+name+'.paj.clu',
# 	graph_path: path+name+'.txt', 
# 	clusters_path: path+name+'.clu',
# 	directed: false,
# 	first_node_id: 1
# )

# path = '/home/vahid/Dropbox/cuda/samples/'
# Dataset.create_dataset_from_paj_file(
# 	graph_input: path+'polblogs.paj', 
# 	clusters_input: path+'polblogs.paj.clu',
# 	graph_path: path+'polblogs.txt', 
# 	clusters_path: path+'polblogs.clu',
# 	directed: false,
# 	first_node_id: 1
# )

# path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/citeseer/'
# Dataset.create_dataset_from_cites_file(
# 	graph_input: path+'citeseer.cites', 
# 	clusters_input: path+'citeseer.content',
# 	graph_path: path+'citeseer.txt', 
# 	clusters_path: path+'citeseer.clu',
# 	directed: true,
# 	first_node_id: 1
# )

# path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/cora/'
# Dataset.create_dataset_from_cites_file(
# 	graph_input: path+'cora.cites', 
# 	clusters_input: path+'cora.content',
# 	graph_path: path+'cora.txt', 
# 	clusters_path: path+'cora.clu',
# 	directed: true,
# 	first_node_id: 1
# )
run(ARGV)
