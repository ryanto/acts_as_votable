module ActsAsVotable::Alias

  def self.words_to_alias object, words, call_function


    words.each do |word|
      if word.is_a?(String)
        function = word.pluralize.to_sym
        if !object.respond_to?(function)
          object.send(:alias_method, function, call_function)
        end
      end
    end
  end

end