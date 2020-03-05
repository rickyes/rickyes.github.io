
{% if page.comments and config.gitalk.enable %}
  <link rel="stylesheet" href="{{ config.gitalk.gitalk_css }}">
  <script src="{{ config.gitalk.gitalk_js }}"></script>
  <script src="{{ config.gitalk.md5 }}"></script>
  <script>
      var gitalk = new Gitalk({
        clientID: '{{ config.gitalk.clientID }}',
        clientSecret: '{{ config.gitalk.clientSecret }}',
        repo: '{{ config.gitalk.repo }}',
        owner: '{{ config.gitalk.owner }}',
        admin: '{{ config.gitalk.admin }}',
        id: md5(location.pathname),
        distractionFreeMode: 'true'
      });
      var div = document.createElement('div');
      div.setAttribute("id", "gitalk_comments");
      div.setAttribute("class", "post-nav");
      var bro = document.getElementById('posts').getElementsByTagName('article');
      bro = bro[0].getElementsByClassName('post-block');
      bro = bro[0].getElementsByTagName('footer');
      bro = bro[0];
      bro.appendChild(div);
      gitalk.render('gitalk_comments');
  </script>
{% endif %}