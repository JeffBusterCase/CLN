require 'yaml'

class ConnectionLinkNet
    attr_reader :name, :mem_connection
    def initialize name, filename=nil
        @mem_connection = {___n___: 0}
        @mem_connection = YAML.load(File.read(filename)) if filename != nil
        @name = name
    end
    
    def filename=(name)
        @mem_connection = YAML.load File.read(name)    
    end
    
    def create(*name)
        for nome in name
            # Check existence
            next if @mem_connection.include? nome.to_sym
        
            @mem_connection[:___n___] += 1
            @mem_connection[nome.to_sym] = {___cod___: @mem_connection[:___n___], connect: []}
        end
    end
    
    def dump
        File.open(@name, 'w'){|file|
            file.puts YAML.dump(@mem_connection)
        }
    end
    def dump!( filename=@name, password=@name+"__________________", iv=@name+"__________________")
        require 'zlib'
        require 'openssl'
        save = YAML.dump(@mem_connection)
        crypter = OpenSSL::Cipher.new('AES-128-CFB')
        crypter.encrypt
        crypter.key = password
        crypter.iv = iv
        crypter.update(save) + crypter.final
        save = Zlib::Deflate.deflate(save)
        File.open(filename, 'w'){|file|
            file.puts save
        }
    end
    def load(filename=@name)
        @mem_connection = YAML.load(filename)
    end
    def load!(filename=@name, password=@name+"_____________", iv=@name+"_______________")
        require 'zlib'
        require 'openssl'
        
        save = Zlib::Inflate.inflate(IO.read(filename))
        
        decrypter = OpenSSL::Cipher.new('AES-128-CFB')
        decrypter.decrypt
        decrypter.key = password
        decrypter.iv = iv
        decrypter.update(save) + decrypter.final
        @mem_connection = YAML.load(save)
    end
    def find sujeito, classe
        query = []
        @mem_connection[classe.to_sym][:connect].each {|x|
            query << x if @mem_connection[sujeito.to_sym][:connect].include? x
        }
        arr = []
        @mem_connection.each{|key, value|
            next if key == :___n___
            arr << key.to_s if query.include? value[:___cod___]
        }
        return arr
    end
    
    def list block
        list_ = []
        @mem_connection.each {|key, value|
            next if key == :___n___
            list_ << key.to_s if @mem_connection[block.to_sym][:connect].include? value[:___cod___]
        }
        
        return list_
    end
    def connect(block, to_block)
        unless @mem_connection[block.to_sym][:connect].include? @mem_connection[to_block.to_sym][:___cod___]
            @mem_connection[block.to_sym][:connect] << @mem_connection[to_block.to_sym][:___cod___]
        end
        unless @mem_connection[to_block.to_sym][:connect].include? @mem_connection[block.to_sym][:___cod___]
            @mem_connection[to_block.to_sym][:connect] << @mem_connection[block.to_sym][:___cod___]
        end
    end
    def update(block , to_block, new_value)
        older_blocks = find(block, to_block)
        
        if older_blocks.empty?
            return False
        end
        for older_block in older_block
            @mem_connection[block.to_sym][:connect].delete(
                @mem_connection[older_block.to_sym][:___cod___])
            @mem_connection[older_block.to_sym][:connect].delete(
                @mem_connection[block.to_sym][:___cod___])
            @mem_connection.delete(older_block.to_sym) if list(older_block).empty?
        end
        create(new_value)
        connect(block, new_value)
        connect(to_block, new_value)
    end
    def link(block, to_block, value)
        connect(block, value)
        connect(to_block, value)
    end
end
