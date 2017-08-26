# frozen_string_literal: true

module ActsAsVotable
  module Cacheable
    def scope_cache_field(field, vote_scope)
      return field if vote_scope.nil?

      case field
      when :cached_votes_total=
        "cached_scoped_#{vote_scope}_votes_total="
      when :cached_votes_total
        "cached_scoped_#{vote_scope}_votes_total"
      when :cached_votes_up=
        "cached_scoped_#{vote_scope}_votes_up="
      when :cached_votes_up
        "cached_scoped_#{vote_scope}_votes_up"
      when :cached_votes_down=
        "cached_scoped_#{vote_scope}_votes_down="
      when :cached_votes_down
        "cached_scoped_#{vote_scope}_votes_down"
      when :cached_votes_score=
        "cached_scoped_#{vote_scope}_votes_score="
      when :cached_votes_score
        "cached_scoped_#{vote_scope}_votes_score"
      when :cached_weighted_total
        "cached_weighted_#{vote_scope}_total"
      when :cached_weighted_total=
        "cached_weighted_#{vote_scope}_total="
      when :cached_weighted_score
        "cached_weighted_#{vote_scope}_score"
      when :cached_weighted_score=
        "cached_weighted_#{vote_scope}_score="
      when :cached_weighted_average
        "cached_weighted_#{vote_scope}_average"
      when :cached_weighted_average=
        "cached_weighted_#{vote_scope}_average="
      end
    end

    def update_cached_votes(vote_scope = nil)
      updates = {}

      if self.respond_to?(:cached_votes_total=)
        updates[:cached_votes_total] = count_votes_total(true)
      end

      if self.respond_to?(:cached_votes_up=)
        updates[:cached_votes_up] = count_votes_up(true)
      end

      if self.respond_to?(:cached_votes_down=)
        updates[:cached_votes_down] = count_votes_down(true)
      end

      if self.respond_to?(:cached_votes_score=)
        updates[:cached_votes_score] = (
        (updates[:cached_votes_up] || count_votes_up(true)) -
        (updates[:cached_votes_down] || count_votes_down(true))
        )
      end

      if self.respond_to?(:cached_weighted_total=)
        updates[:cached_weighted_total] = weighted_total(true)
      end

      if self.respond_to?(:cached_weighted_score=)
        updates[:cached_weighted_score] = weighted_score(true)
      end

      if self.respond_to?(:cached_weighted_average=)
        updates[:cached_weighted_average] = weighted_average(true)
      end

      if vote_scope
        if self.respond_to?(scope_cache_field :cached_votes_total=, vote_scope)
          updates[scope_cache_field :cached_votes_total, vote_scope] = count_votes_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_up=, vote_scope)
          updates[scope_cache_field :cached_votes_up, vote_scope] = count_votes_up(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_down=, vote_scope)
          updates[scope_cache_field :cached_votes_down, vote_scope] = count_votes_down(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_total=, vote_scope)
          updates[scope_cache_field :cached_weighted_total, vote_scope] = weighted_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_score=, vote_scope)
          updates[scope_cache_field :cached_weighted_score, vote_scope] = weighted_score(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_score=, vote_scope)
          updates[scope_cache_field :cached_votes_score, vote_scope] = (
          (updates[scope_cache_field :cached_votes_up, vote_scope] || count_votes_up(true, vote_scope)) -
          (updates[scope_cache_field :cached_votes_down, vote_scope] || count_votes_down(true, vote_scope))
          )
        end

        if self.respond_to?(scope_cache_field :cached_weighted_average=, vote_scope)
          updates[scope_cache_field :cached_weighted_average, vote_scope] = weighted_average(true, vote_scope)
        end
      end

      if (::ActiveRecord::VERSION::MAJOR == 3) && (::ActiveRecord::VERSION::MINOR != 0)
        self.update_attributes(updates, without_protection: true) if updates.size > 0
      else
        self.update_attributes(updates) if updates.size > 0
      end
    end

    # counting
    def count_votes_total(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_total, vote_scope)
        return self.send(scope_cache_field :cached_votes_total, vote_scope)
      end
      find_votes_for(scope_or_empty_hash(vote_scope)).count
    end

    def count_votes_up(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_up, vote_scope)
        return self.send(scope_cache_field :cached_votes_up, vote_scope)
      end
      get_up_votes(vote_scope: vote_scope).count
    end

    def count_votes_down(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_down, vote_scope)
        return self.send(scope_cache_field :cached_votes_down, vote_scope)
      end
      get_down_votes(vote_scope: vote_scope).count
    end

    def count_votes_score(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_votes_score, vote_scope)
        return self.send(scope_cache_field :cached_votes_score, vote_scope)
      end
      ups = count_votes_up(true, vote_scope)
      downs = count_votes_down(true, vote_scope)
      ups - downs
    end

    def weighted_total(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_total, vote_scope)
        return self.send(scope_cache_field :cached_weighted_total, vote_scope)
      end
      ups = get_up_votes(vote_scope: vote_scope).sum(:vote_weight)
      downs = get_down_votes(vote_scope: vote_scope).sum(:vote_weight)
      ups + downs
    end

    def weighted_score(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_score, vote_scope)
        return self.send(scope_cache_field :cached_weighted_score, vote_scope)
      end
      ups = get_up_votes(vote_scope: vote_scope).sum(:vote_weight)
      downs = get_down_votes(vote_scope: vote_scope).sum(:vote_weight)
      ups - downs
    end

    def weighted_average(skip_cache = false, vote_scope = nil)
      if !skip_cache && self.respond_to?(scope_cache_field :cached_weighted_average, vote_scope)
        return self.send(scope_cache_field :cached_weighted_average, vote_scope)
      end

      count = count_votes_total(skip_cache, vote_scope).to_i
      if count > 0
        weighted_score(skip_cache, vote_scope).to_f / count
      else
        0.0
      end
    end
  end
end
