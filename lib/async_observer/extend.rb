# async-observer - Rails plugin for asynchronous job execution

# Copyright (C) 2007 Philotic Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'async_observer/queue'

CLASSES_TO_EXTEND = [
  Array,
  Hash,
  Module,
  Numeric,
  Range,
  String,
  Symbol,
]

module AsyncObserver::Extensions
  def async_send(selector, *args)
    async_send_opts(selector, {}, *args)
  end

  def async_send_opts(selector, opts, *args)
    AsyncObserver::Queue.put_call!(self, selector, opts, args)
  end
end

# General extensions
CLASSES_TO_EXTEND.each do |c|
  c.send :include, AsyncObserver::Extensions
end

# Specific extensions
if defined?(ActiveRecord)
  require 'async_observer/active_record'
end


class Range
  DEFAULT_FANOUT_FUZZ = 0
  DEFAULT_FANOUT_DEGREE = 1000

  def split_to(n)
    split_by((size + n - 1) / n) { |group| yield(group) }
  end

  def split_by(n)
    raise ArgumentError.new('invalid slice size') if n < 1
    n -= 1 if !exclude_end?
    i = first
    while member?(i)
      j = [i + n, last].min
      yield(Range.new(i, j, exclude_end?))
      i = j + (exclude_end? ? 0 : 1)
    end
  end

  def size
    last - first + (exclude_end? ? 0 : 1)
  end

  def async_each_opts(rcv, selector, opts, *extra)
    fanout_degree = opts.fetch(:fanout_degree, DEFAULT_FANOUT_DEGREE)
    if size <= fanout_degree
      each {|i| rcv.async_send_opts(selector, opts, i, *extra)}
    else
      fanout_opts = opts.merge(:fuzz => opts.fetch(:fanout_fuzz,
                                                   DEFAULT_FANOUT_FUZZ))
      fanout_opts[:pri] = opts[:fanout_pri] || opts[:pri]
      fanout_opts = fanout_opts.reject_hash{|k,v| nil.equal?(v)}
      split_to(fanout_degree) do |subrange|
        subrange.async_send_opts(:async_each_opts, fanout_opts, rcv, selector,
                                 opts, *extra)
      end
    end
  end

  def async_each(rcv, selector, *extra)
    async_each_opts(rcv, selector, {}, *extra)
  end
end
