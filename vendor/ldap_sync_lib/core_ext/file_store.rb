# encoding: utf-8
class ActiveSupport::Cache::FileStore
  def delete_unless(&block)
    default_options = merged_options({})
    search_dir(cache_path) do |path|
      key = file_path_key(path)
      delete_entry(path, **default_options) unless block.call(key)
    end
  end
end
