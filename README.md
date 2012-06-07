プロシージャをキャッシュします。

次のように、結果は何らかのトリガーが発生するまで変化しなくて、毎回呼ぶには重い処理。

	def calc
	  return 重い処理
	end

次のようにすることで、2回目以降の呼び出しではキャッシュされた結果を返します。

	require 'proc_cache'
	def calc
	  return proc_cache do
	    重い処理
	  end
	end

キーを指定してキャッシュされる範囲を指定したり、有効期限を指定することもできます。

	proc_cache(
	  :keys => [:layer1, :layer2],
	  :expire => 1.days.since) { ... }

明示的にキャッシュをクリアするには次のようにします。

	expire_proc_cache :layer1, :layer2