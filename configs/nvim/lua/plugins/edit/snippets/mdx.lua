return {
	s(
		{
			trig = "blog",
			name = "ブログ用ヘッダー",
			desc = "ブログ用に作成したヘッダー",
		},
		fmt(
			[[
      title: '{}'
      description: '{}'
      pubDate: '2024-12-29'
      heroImage: '/blog-placeholder-5.jpg'
      tags: ['{}']
      ---
    ]],
			{
				i(1, "title"),
				i(2, "desc"),
				i(3, "tag"),
			}
		)
	),
}
