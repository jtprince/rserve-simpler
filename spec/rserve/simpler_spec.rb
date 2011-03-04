require 'spec_helper'

require 'rserve/simpler'

describe "initializing a connection held in 'R'" do
  it 'require "rserve/simpler/R" # loads a connection into R' do
    require 'rserve/simpler/R'
    R.converse("mean(c(1,2,3))").is 2.0
    R.close
  end
end

describe 'rserve connection with simpler' do
  xit 'is quiet on startup' do
    @r = Rserve::Simpler.new
  end
end

describe 'rserve connection with simpler additions' do

  before do
    @r = Rserve::Simpler.new 
  end

  after do
    @r.close
  end

  it 'converses with R using strings' do
  # both sides speak native
    ok @r.connected?
    reply = @r.converse "mean(c(1,2,3))"
    @r.converse("mean(c(1,2,3))").is 2.0
  end

  it 'converses with R using arrays and numbers' do
    @r.converse("cor(a,b)", :a => [1,2,3], :b => [4,5,6]).is 1.0
    @r.converse(:a => [1,2,3], :b => [4,5,6]) { "cor(a,b)" }.is 1.0
    @r.converse(:a => 3) { "mean(a)" }.is 3.0
  end

  it 'can converse in sentences' do
    (mean, cor) = @r.converse("mean(a)", "cor(a,b)", :a => [1,2,3], :b => [4,5,6])
    mean.is 2.0
    cor.is 1.0
    # not sure why you'd want to do this, but this is okay
    (mean, cor) = @r.converse("mean(a)") { "cor(a,b)" } 
    # also okay
    (mean, cor) = @r.converse "mean(a)", "cor(a,b)"
  end

  it 'has a prompt-like syntax' do
    reply = @r >> "mean(c(1,2,3))"
    reply.is 2.0
    reply = @r.>> "cor(a,b)", a: [1,2,3], b: [1,2,3]
    reply.is 1.0
  end

  it "commands R (giving no response but 'true')" do
    @r.command(:a => [1,2,3], :b => [4,5,6]) { "z = cor(a,b)" }.is true
    @r.converse("z").is 1.0
  end

  it "convert to REXP" do
    reply =  @r.convert(:a => [1,2,3], :b => [4,5,6]) { "cor(a,b)" }
    ok reply.is_a?(Rserve::REXP::Double)
    reply.as_doubles.is [1.0]
    reply.to_ruby .is 1.0
  end

  xit "returns the REXP if to_ruby raises an error" do
    # still need to test this
    flunk
  end

end

begin
  require 'narray'
  describe 'compatible with NArray' do
    before do
      @r = Rserve::Simpler.new
    end
    it 'takes NArray vectors as input' do
      @r.converse(x: NArray[1,2,3], y: NArray[4,5,6]) { "cor(x,y)" }.is 1.0
    end
  end
rescue LoadError
  xdescribe "compatible with NArray [narray not installed!]"
end


if RUBY_VERSION > '1.9'

  # TODO: write these compatible for 1.8

  describe 'rserve with DataFrame convenience functions' do

    Row = Struct.new(:fac1, :var1, :res1)

    before do
      @r = Rserve::Simpler.new 
      @hash = {:fac1 => [1,2,3,4], :var1 => [4,5,6,7], :res1 => [8,9,10,11]}
      @colnames = %w(fac1 var1 res1).map(&:to_sym)
      @ar_of_structs = [Row.new(1,4,8), Row.new(2,5,9), Row.new(3,6,10), Row.new(4,7,11)]
			@ar_of_structs_makes_nils = [Row.new(1,4,8), Row.new(2,5,9)] 
			@hash2 = {:fac1 => [1,2], :var1 => [4,5], :res1 => [8,9]}

    end

    after do
      @r.close
    end

    it 'gives hashes a .to_dataframe method' do
      # only need to set the colnames with Ruby 1.8 (unless using OrderedHash)
      df1 = Rserve::DataFrame.new(@hash) 
      df2 = @hash.to_dataframe
      df2.colnames.is @colnames
      df1.is df2
      df2.colnames.is @colnames
      df2.rownames.is nil
      df2.rownames = [1,2,3,4]
      df2.rownames.is [1,2,3,4]
    end

    it 'allows colnames to be set if necessary' do
      df1 = Rserve::DataFrame.new(@hash) 
      df1.colnames.enums [:fac1, :var1, :res1]
      df1.colnames = %w(word to yo)
      df1.colnames.enums %w(word to yo)
      @r.converse(df: df1) { "names(df)" }.enums %w(word to yo)
    end

    it 'converts an array of parallel structs into a dataframe' do
      df = Rserve::DataFrame.from_structs( @ar_of_structs )
      df.is @hash.to_dataframe
    end

		it 'converts an array of parallel structs into a dataframe without generating nils' do
      df = Rserve::DataFrame.from_structs( @ar_of_structs_makes_nils )
      df.is @hash2.to_dataframe
    end

    it 'accepts simple dataframes when conversing with R' do
      @r.converse(:df => @hash.to_dataframe) { "names(df)" }.is %w(fac1 var1 res1)
    end

    it 'accepts dataframes with rownames when conversing with R' do
      rownames = [11,12,13,14]
      @r.converse(:df => @hash.to_dataframe(rownames)) { "row.names(df)" }.is rownames.map(&:to_s)
      rownames = %w(row1 row2 row3 row4)
      @r.converse(:df => @hash.to_dataframe(rownames)) { "row.names(df)" }.is rownames
    end
  end

end
