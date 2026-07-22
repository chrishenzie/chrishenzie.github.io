(function () {
  "use strict";
  var canvas = document.getElementById("sky");
  if (!canvas) return;
  var ctx = canvas.getContext("2d");
  var reduce = matchMedia("(prefers-reduced-motion: reduce)");
  var W = 0, H = 0, DPR = 1;
  var stars = [];
  var t0 = performance.now(), raf = 0;
  var STAR = "230,231,224"; // warm cream on the night gradient

  // deterministic seed so the field is stable across frames and resizes
  function mulberry32(s) {
    return function () {
      s |= 0; s = s + 0x6D2B79F5 | 0;
      var t = Math.imul(s ^ s >>> 15, 1 | s);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  function build() {
    var rnd = mulberry32(20260722);
    var count = Math.round((W * H) / 12000);
    count = Math.max(50, Math.min(170, count));
    stars = [];
    for (var i = 0; i < count; i++) {
      stars.push({
        x: rnd() * W, y: rnd() * H,
        r: 0.5 + rnd() * rnd() * 1.7,
        base: 0.26 + rnd() * 0.5,
        tw: rnd() * 6.28, tws: 0.4 + rnd() * 0.9,
        vx: (rnd() - 0.5) * 0.03, vy: (rnd() - 0.5) * 0.03
      });
    }
  }

  function resize() {
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    W = window.innerWidth; H = window.innerHeight;
    canvas.width = W * DPR; canvas.height = H * DPR;
    canvas.style.width = W + "px"; canvas.style.height = H + "px";
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    build();
  }

  function draw(now) {
    var still = reduce.matches;
    var time = (now - t0) / 1000;
    ctx.clearRect(0, 0, W, H);
    for (var i = 0; i < stars.length; i++) {
      var s = stars[i];
      if (!still) {
        s.x += s.vx; s.y += s.vy;
        if (s.x < 0) s.x += W; if (s.x > W) s.x -= W;
        if (s.y < 0) s.y += H; if (s.y > H) s.y -= H;
      }
      var tw = still ? 1 : 0.72 + 0.28 * Math.sin(time * s.tws + s.tw);
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, 6.2832);
      ctx.fillStyle = "rgba(" + STAR + "," + (s.base * tw).toFixed(3) + ")";
      ctx.fill();
    }
    raf = requestAnimationFrame(draw);
  }

  window.addEventListener("resize", resize);

  resize();
  raf = requestAnimationFrame(draw);
})();
