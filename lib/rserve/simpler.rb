
require 'rserve'
require 'rserve/rexp'
require 'rserve/data_frame'

class Rserve::Simpler < Rserve::Connection

  # assigns variables and returns an array of commands to be evaluated
  def with(*args, &block)
    if args.last.is_a? Hash
      hash = args.pop  # remove the hash
      hash.each do |sym, obj|
        rserve_compat_obj = 
          case obj
          when Rserve::DataFrame
            wrapped_lists = obj.hash.values.map {|v| Rserve::REXP::Wrapper.wrap(v) }
            z = Rserve::Rlist.new(wrapped_lists, obj.hash.keys.map(&:to_s))
            Rserve::REXP.create_data_frame(z)
          else
            obj
          end

        assign sym.to_s, rserve_compat_obj

        # this is super hackish but I tried "correct" methods to do this
        # and they do not want to work.
        # TODO: roll creation of row.names into create_data_frame method
        if obj.is_a?(Rserve::DataFrame) && obj.rownames
          tmp_var = "#{sym}__rownames__tmp__"
          # all rownames become string arrays:
          assign tmp_var, Rserve::REXP::String.new(obj.rownames)
          void_eval( ["row.names(#{sym}) <- #{tmp_var}", "rm(#{tmp_var})"].join("\n") )
        end

      end
    end
    to_eval = args
    unless block.nil?
      to_eval << block.call
    end
    to_eval
  end

  def converse(*args, &block)
    reply = with(*args, &block).map do |str|
      response = self.eval(str)
      reply = nil
      begin ; reply = response.to_ruby 
      rescue ; reply = response
      end
      reply
    end
    (reply.size == 1) ?  reply.first : reply
  end

  alias_method '>>'.to_sym, :converse

  def command(*args, &block)
    self.void_eval with(*args, &block).join("\n")
  end

end
