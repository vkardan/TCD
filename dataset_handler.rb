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

	def self.create_dataset_from_snap_file(graph_input:, clusters_input:, graph_path:, clusters_path:, directed:, first_node_id: 1)
		m = 0
		node_id = first_node_id
		cluster_id = 1
		id_dic = Hash.new
		cluster_dic = Hash.new
		graph = Hash.new
		fi = File.open(clusters_input, "r")
		fi.each_line do |line|
			items = line.split(/\s/) - [""]
			cluster_dic[cluster_id] = []
			items.each do |itm|
				if id_dic[itm].nil? then 
					id_dic[itm] = node_id
					graph[node_id] = {}	
					graph[node_id]['cluster'] = []
					node_id += 1
				end
				graph[id_dic[itm]]['cluster'] << cluster_id
				cluster_dic[cluster_id] << id_dic[itm]
			end
			cluster_id += 1
		end

		fi = File.open(graph_input, "r")
		fi.each_line do |line| 
			items = line.split(/\s/) - [""]
			next if items[0][0] == "#"
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
		File.open(clusters_path+'.v1', 'w') do |c|
			graph.each do |node, h|
				raise "Bad format, no cluster found for node: #{node}" if h['cluster'].nil?
				h['cluster'].each do |itm|
					c.puts "#{node} #{itm}"
				end
			end
		end
		File.open(clusters_path, 'w') do |c|
			cluster_dic.each do |clusid, mem|
				c.puts mem.join(' ')
			end
		end
		File.open(graph_path, 'w') do |g|
			graph.each do |node, h|
				h['children'].sort.each { |child| g.puts "#{node} #{child}" } unless h['children'].nil?
			end
		end
		File.open(graph_path+'.meta', 'w') {|f| f.puts "N: #{graph.size}, M: #{m}, C: #{cluster_dic.size}"}
	end

	def self.convert_cluster_file(clusters_input:)
		cluster_dic = Hash.new
		fi = File.open(clusters_input, "r")
		fi.each_line do |line|
			items = line.split(/\s/) - [""]
			next if items[0][0] == "#" || items[0][0] == "*"
			nid = items[0]
			cid = items[1]
			cluster_dic[cid] ||= []
			cluster_dic[cid] << nid
		end

		File.open(clusters_input+'.v2', 'w') do |c|
			cluster_dic.each do |clusid, mem|
				c.puts mem.join(' ')
			end
		end
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
			if graph[node_id].nil? then
				puts "Warning unknown node id: "+items[0] 
				next
			end
			graph[node_id]["k"] = node_cluster
			k[node_cluster] ||= []
			k[node_cluster] << node_id
		end

		a = create_contingency_table graph: graph, c: c.keys, k: k.keys
		homo = homogeneity a: a, k: k.keys, c: c.keys, n: graph.size
		comp = completeness a: a, k: k.keys, c: c.keys, n: graph.size
		puts "c: #{comp} , h: #{homo}"
		vm = v_measure homo: homo, comp: comp
		nmi = nmi_measure a: a, k: k.keys, c: c.keys, n: graph.size
		puts "V-measure: #{vm} , NMI: #{nmi}"
		return {c: comp, h: homo, vm: vm, nmi: nmi}
	end

	def evaluate2(real_classes_path:, clusters_path:)
		graph = Hash.new
		c = Hash.new
		k = Hash.new
		class_id = 1
		File.open(real_classes_path, "r").each_line do |line|
			items = line.split(/\s/) - [""]
			next if items[0] == '#'
			node_id = items[0]
			node_class = items[1]
			graph[node_id] ||= {}
			graph[node_id]["c"] ||= []
			graph[node_id]["c"] << node_class
			c[node_class] ||= []
			c[node_class] << node_id
		end
		puts "Ground truth labels are loaded."

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
			if graph[node_id].nil? then
				puts "Warning unknown node id: "+items[0] 
				next
			end
			graph[node_id]["k"] ||= []
			graph[node_id]["k"] << node_cluster
			k[node_cluster] ||= []
			k[node_cluster] << node_id
		end
		puts "Clusters are loaded."

		a = create_contingency_table2 graph: graph, c: c.keys, k: k.keys
		puts "Contigency table has been created."

		homo = homogeneity a: a, k: k.keys, c: c.keys, n: graph.size
		comp = completeness a: a, k: k.keys, c: c.keys, n: graph.size
		puts "c: #{comp} , h: #{homo}"
		vm = v_measure homo: homo, comp: comp
		nmi = nmi_measure a: a, k: k.keys, c: c.keys, n: graph.size
		puts "V-measure: #{vm} , NMI: #{nmi}"
		return {c: comp, h: homo, vm: vm, nmi: nmi}
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

	def create_contingency_table2(graph:, c:, k:)
		a = Hash.new
		c.each do |i|
			a[i]=Hash.new
			k.each do |j|
				a[i][j] = 0
			end
		end
		graph.each do |node, h|
			h["c"].each do |cid|
				h["k"].each do |kid|
					a[cid][kid] += 1.0/(h["c"].size*h["k"].size)
				end
			end
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

	def v_measure(homo:, comp:, beta: 1)
		return (1+beta)*homo*comp/(beta*homo+comp)
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
 
 	eval_fun = 
 		case params[0]
 		when 'e1'
 			'e1'
 		when 'e2'
 			'e2'
 		else
 			puts 'Unknown evaluation function!'
 			return
 		end

	ground_truth_path = '../Dropbox/Vahid-Research/community-detection/datasets/'
	algo_path = 
		case params[1]
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
		case params[2]
		when 'k'
			'karate'
		when 'p'
			'polblogs'
		when 'b'
			'polbooks'
		when 'co'
			'cora'
		when 'ci'
			'citeseer'
		when 'y'
			'yeast'
		when 'f'
			'football'
		when 'am'
			'amazon'
		when 'gd'
			'generated/directed'
		when 'gu'
			'generated/undirected'
		else
			puts 'Unknown dataset!'
			return
		end

	avg_c = 0.0
	avg_h = 0.0
	avg_vm = 0.0
	avg_nmi = 0.0
	
	dev_c = 0.0
	dev_h = 0.0
	dev_vm = 0.0
	dev_nmi = 0.0

	clusters_path = algo_path+"#{dataset_name}/"
	clusters_path += "#{params[3]}/" if params[3] != nil
	clusters_path += "*"

	puts "=========================================================="
	Dir[clusters_path].each do |name|	
		puts name.split('/')[-1]
		if params[3] != nil then
			real_classes_path = ground_truth_path+"#{dataset_name}/#{params[3]}/#{name.split('/')[-1]}"
		else
			real_classes_path = ground_truth_path+"#{dataset_name}/#{dataset_name}.clu"
		end

		r = {}
		if eval_fun == 'e1' then
			r=Dataset.new.evaluate(
				real_classes_path: real_classes_path, 
				clusters_path: name
			)
		else
			r=Dataset.new.evaluate2(
				real_classes_path: real_classes_path, 
				clusters_path: name
			)
		end

		puts "=========================================================="
		avg_c += r[:c]
		avg_h += r[:h]
		avg_vm += r[:vm]
		avg_nmi += r[:nmi]

		dev_c += r[:c]**2
		dev_h += r[:h]**2
		dev_vm += r[:vm]**2
		dev_nmi += r[:nmi]**2
	end
	num_files = Dir[clusters_path].size
	avg_c = avg_c/num_files
	avg_h = avg_h/num_files
	avg_vm = avg_vm/num_files
	avg_nmi = avg_nmi/num_files

	dev_c = (dev_c/num_files - avg_c**2)**0.5
	dev_h = (dev_h/num_files - avg_h**2)**0.5
	dev_vm = (dev_vm/num_files - avg_vm**2)**0.5
	dev_nmi = (dev_nmi/num_files - avg_nmi**2)**0.5
	puts "----------------------------------------------------------"
	puts "Measure\t\tAvg.\t\t\tSD."
	puts "----------------------------------------------------------"
	puts "Completeness:\t#{avg_c} ,\t#{dev_c}\nHomogenity:\t#{avg_h} ,\t#{dev_h}"
	puts "V-measure:\t#{avg_vm} ,\t#{dev_vm}\nNMI:\t\t#{avg_nmi} ,\t#{dev_nmi}"
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

# name = "polbooks"
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

# path = '/home/vahid/Desktop/Amazon/'
# Dataset.create_dataset_from_snap_file(
# 	graph_input: path+'com-amazon.ungraph.txt', 
# 	clusters_input: path+'com-amazon.all.dedup.cmty.txt',
# 	graph_path: path+'amazon.txt', 
# 	clusters_path: path+'amazon.clu',
# 	directed: false,
# 	first_node_id: 1
# )
Dataset.convert_cluster_file clusters_input: "/home/vahid/Desktop/amazon.clu"
#run(ARGV)
