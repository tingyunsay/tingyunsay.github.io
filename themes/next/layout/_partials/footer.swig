<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}</span>
</div>

<script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js">
</script>
{% if theme.copyright %}
<div class="powered-by">
  {{ __('footer.powered', '<a class="theme-link" href="https://hexo.io">Hexo</a>') }}
</div>

<div class="theme-info">
  {{ __('footer.theme') }} -
  <a class="theme-link" href="https://github.com/iissnan/hexo-theme-next">
    NexT.{{ theme.scheme }}
  </a>
</div>
<span id="busuanzi_container_site_pv" class="times">
	&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;本站总访问量<span id="busuanzi_value_site_pv"></span>次
</span>
{% endif %}

<script src="//cdn1.lncld.net/static/js/2.5.0/av-min.js"></script>
<script>
    var APP_ID = '<%- config.leancloud_visitors.app_id %>';
    var APP_KEY = '<%- config.leancloud_visitors.app_key %>';
    AV.init({
        appId: APP_ID,
        appKey: APP_KEY
    });
    // 显示次数
    function showTime(Counter) {
        var query = new AV.Query("Counter");
        if($(".leancloud_visitors").length > 0){
            var url = $(".leancloud_visitors").attr('id').trim();
            // where field
            query.equalTo("words", url);
            // count 
            query.count().then(function (number) {
                // There are number instances of MyClass where words equals url.
                $(document.getElementById(url)).text(number?  number : '--');
            }, function (error) {
                // error is an instance of AVError.
            });
        }
    }
   // 追加pv
    function addCount(Counter) {
        var url = $(".leancloud_visitors").length > 0 ? $(".leancloud_visitors").attr('id').trim() : 'icafebolger.com';
        var Counter = AV.Object.extend("Counter");
        var query = new Counter;
        query.save({
            words: url
        }).then(function (object) {
        })
    }
    $(function () {
        var Counter = AV.Object.extend("Counter");
        addCount(Counter);
        showTime(Counter);
    });
</script>

