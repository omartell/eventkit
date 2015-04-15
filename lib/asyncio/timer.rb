module AsyncIO
  Timer = Struct.new(:expires_in, :handler) do
    def initialize(seconds, handler)
      super(Time.now.to_f + seconds, handler)
    end

    def <=>(other)
      expires_in <=> other.expires_in
    end

    def expired?
      expires_in <= Time.now.to_f
    end
  end
end
