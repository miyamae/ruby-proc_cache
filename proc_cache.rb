# -*- coding: utf-8 -*-
# =====================================================================
# プロシージャキャッシュ 1.0.0 (2010/12/29)
# (C) 2010 BitArts, Inc.
# Author: Tatsuya Miyamae <miyamae@bitarts.co.jp>
# =====================================================================

class Object

  #デフォルトロガー
  def logger
    require "logger"
    Logger.new(STDOUT)
  end

  # プロシージャキャッシュ
  # proc_cache(:keys=>[:layer1, :layer2], :expire=>1.days.since) { ... }
  @@proc_cache_data = Hash.new
  def proc_cache(args={}, &block)
    keys = (args[:keys] or ["_default"])
    unless @@proc_cache_data[self.class]
      @@proc_cache_data[self.class] = Hash.new
      logger.debug "New procedure cache: #{self.class}"
    end
    data = @@proc_cache_data[self.class].tree(keys)
    if data && (!data[:expire] || data[:expire] > Time.now)
      logger.debug "Cached procedure hit: #{self.class} #{keys.inspect}"
    else
      if data
        logger.debug "Cached procedure expired at #{data[:expire]}: #{self.class} #{keys.inspect}"
      else
        logger.debug "Cached procedure miss: #{self.class} #{keys.inspect}"
      end
      @@proc_cache_data[self.class].store_tree(
        {:expire=>args[:expire], :value=>block.call}, keys)
    end
    logger.debug "Cache(#{self.class}): " + @@proc_cache_data[self.class].inspect
    @@proc_cache_data[self.class].tree(keys)[:value]
  end

  # プロシージャキャッシュを失効
  def self.expire_proc_cache(*keys)
    if @@proc_cache_data[self]
      @@proc_cache_data[self].clear
      logger.debug "Cleared procedure cache: #{self} #{keys.inspect}"
      logger.debug "Cache(#{self}): " + @@proc_cache_data[self].inspect
    end
  end

  def expire_proc_cache(*keys)
    self.class.expire_proc_cache(*keys)
  end

end


class Hash

private

  def tree_code(*args)
    keys = args[0].is_a?(Array) ? args[0] : (args or [])
    s = "self"
    keys.each do |key|
      if key.is_a?(Numeric)
        s += %{[#{key}]}
      elsif key.is_a?(Symbol)
        s += %{[:#{key}]}
      elsif key.is_a?(String)
        s += %{['#{key}']}
      else
        s += %{[#{key.hash}]}
      end
    end
    s
  end

public

  # Hash階層を作る
  def add_tree(*args)
    keys = args[0].is_a?(Array) ? args[0] : (args or [])
    unless keys.empty?
      h = self
      keys.each_index do |i|
        key = keys[i]
        if h.is_a?(Hash)
          unless h[key]
            h[key] = Hash.new
          end
          h = h[key]
        end
      end
    end
    self
  end

  # 階層
  def tree(*args)
    keys = args[0].is_a?(Array) ? args[0] : (args or [])
    h = self
    keys.each do |key|
      return nil if !h || !h.key?(key)
      h = h[key]
    end
    h
  end

  # 階層の中に値を入れる
  def store_tree(value, *args)
    add_tree(*args)
    code = tree_code(*args)
    eval "#{code}=value"
  end

  # 階層の中を空にする
  def clear_tree(*args)
    code = tree_code(*args)
    obj = eval(code)
    eval("#{code}=nil")
  end

end
