class SeriesNumberController < ApplicationController

  def list
    @batch = SeriesBatch.paginate(page: params[:page]).order('id DESC')
  end

  def new
    cfg = {
      :count => params[:count] || 50,
      :length => params[:length] || 12,
      :number => params[:number] == "1",
      :alphabet => params[:alphabet] == "1",
      :friendly => params[:friendly] == "1",
      :case_sensitive => params[:case_sensitive] == "1",
      :prefix => params[:prefix] || "",
      :surfix => "",
    }
    if request.post?
      redis = Redis.new
      redis_key = "set_" + get_random_string
      puts redis_key
      
      _pool = "";
      if cfg[:number]
        _pool += (0..9).to_a.join
      end
      if cfg[:alphabet]
        if cfg[:friendly]
          _pool += "CEFGHKMNPQRTWXY"
        else
          _pool += ("A".."Z").to_a.join
        end
      end
      if cfg[:case_sensitive]
        if cfg[:friendly]
          _pool += "adefghijr"
        else
          _pool += ("a".."z").to_a.join
        end
      end
      # 准备字库

      rand_len = cfg[:length].to_i - cfg[:prefix].size - cfg[:surfix].size
      pool_len = _pool.size
      possibility = pool_len ** rand_len
      gaps = possibility / cfg[:count].to_i
      puts possibility, gaps, pool_len

      # seed = 0
      cfg[:count].to_i.times do |i|
        # seed += SecureRandom.random_number(gaps) + 1

        arr = nil
        count = 0
        while !arr || (!count && possibility >= cfg[:count].to_i)
          arr = gen_code possibility, pool_len, rand_len
          # (rand_len - 1).times { arr.push rand(pool_len) }
          count = redis.sadd redis_key, cfg[:prefix] + (arr.map { |item| _pool[item] }).join + cfg[:surfix]
        end
        # puts arr.to_json
      end
      redis.expire redis_key, 300
    elsif request.get?
      cfg[:number] ||= true
      cfg[:friendly] ||= true
    end

    render :locals => {
      cfg: cfg,
      list: (defined? redis) && !redis.nil? && redis.smembers(redis_key).sort || nil,
      gaps: gaps || 0,
      key: redis_key
    }
  end
  
  def download
    key = params[:key]
    if !key.nil? && !key.empty?
      redis = Redis.new
      list = redis.smembers key
      if list.size > 0
        respond_to do |format|
          format.xlsx {
            require 'axlsx'

            Axlsx::Package.new do |p|
              p.workbook.add_worksheet(:name => "List") do |sheet|
                sheet.add_row ["Code"]
                list.sort.each { |label| sheet.add_row [label], :types => [:string] }
              end
              
              send_data p.to_stream.read, filename: "code_#{DateTime.now.to_i.to_s}.xlsx"
            end
          }
          format.csv { send_data list.sort.to_csv, filename: "code_#{DateTime.now.to_i.to_s}.csv" }
        end
      else
        render plain: "Expired", status: 400
      end
    else
      render plain: "Missing params: key", status: 400
    end
  end
  
  private
  
  def get_random_string(length = 8, map = nil)
    map = ("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a if map.nil?
    key = ""
    length.times { key += map[rand(map.size)].to_s }
    key
  end
  
  def gen_code(max, count, len)
    num = SecureRandom.random_number(max)
    arr = [num % count]
    while (num -= arr[0]) > 0
      num /= count
      arr.unshift num % count
    end
    if arr.size < len
      zero = Array.new(len - arr.size)
      zero.fill(0) + arr;
    elsif arr.size > len
      return nil
    else
      arr
    end
  end
  
end
