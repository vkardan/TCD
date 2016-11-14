# This class provides necessary methods for creating datasets. 
#
# @author: Vahid Kardan
class Dataset

	def initialize

	end

	def self.create_dataset_from_gml_file(input:, graph_path:, clusters_path:, first_node_id: 1)
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
				graph[edge['source']]['children'] << edge['target'] 
				m += 1
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
				raise "Bad PAJ file format, keyword '*vertices' was not found!" if items[0].downcase != '*vertices'
				n = items[1].to_i
				state = 1
			when 1
				state = 10 if items[0].downcase == '*edges'
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
				graph[source]['children'] << target
				m += 1
				unless directed then
					graph[target]['children'] ||= []
					graph[target]['children'] << source
					m += 1
				end
			end
		end
		fi = File.open(clusters_input, "r")
		fi.each_line do |line|
			items = line.split(/\s/) - [""]
			node_id = items[0].to_i
			raise "Node with id: #{node_id} not found!" if graph[node_id].nil?
			graph[node_id]['cluster'] = items[1].to_i
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
end

path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/polblogs/'
Dataset.create_dataset_from_gml_file(
	input: path+'polblogs.gml', 
	graph_path: path+'polblogs.txt', 
	clusters_path: path+'polblogs.clu',
	first_node_id: 1
)

path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/karate/'
Dataset.create_dataset_from_paj_file(
	graph_input: path+'karate.paj', 
	clusters_input: path+'karate.paj.clu',
	graph_path: path+'karate.txt', 
	clusters_path: path+'karate.clu',
	directed: false,
	first_node_id: 1
)

path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/citeseer/'
Dataset.create_dataset_from_cites_file(
	graph_input: path+'citeseer.cites', 
	clusters_input: path+'citeseer.content',
	graph_path: path+'citeseer.txt', 
	clusters_path: path+'citeseer.clu',
	directed: true,
	first_node_id: 1
)

path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/cora/'
Dataset.create_dataset_from_cites_file(
	graph_input: path+'cora.cites', 
	clusters_input: path+'cora.content',
	graph_path: path+'cora.txt', 
	clusters_path: path+'cora.clu',
	directed: true,
	first_node_id: 1
)
