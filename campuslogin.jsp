<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%
    if(session.getAttribute("loginUser")!=null){
        String role=(String)session.getAttribute("loginRole");
        if("student".equals(role))        response.sendRedirect("/CAN/main_student.jsp");
        else if("assistant".equals(role)) response.sendRedirect("/CAN/main_assistant.jsp");
        else if("professor".equals(role)) response.sendRedirect("/CAN/main_professor.jsp");
        else if("admin".equals(role))     response.sendRedirect("/CAN/main_admin.jsp");
        else if("visitor".equals(role))   response.sendRedirect("/CAN/main_visitor.jsp");
        else { session.invalidate(); /* guest → 로그인 페이지 표시 */ }
        if(!"guest".equals(session.getAttribute("loginRole"))) return;
    }
    String errorMsg=(String)request.getAttribute("errorMsg"); if(errorMsg==null)errorMsg="";
    String prevId=(String)request.getAttribute("prevId"); if(prevId==null)prevId="";
    String registered=request.getParameter("registered");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ICT CAN — 로그인</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,700;9..40,800&family=DM+Mono:wght@400;500&family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<style>
:root{--white:#fff;--bg:#f0f4f8;--line:#e4e7ed;--line2:#d0d5df;--txt:#111827;--txt2:#4b5563;--txt3:#9ca3af;--blue:#1a56db;--blue-lt:#eff4ff;--blue-md:#c7d7fd;--teal:#0d9488;--teal-lt:#f0fdfa;--teal-md:#99f6e4;--red:#dc2626;--red-lt:#fef2f2;--green:#16a34a;--green-lt:#f0fdf4;--mono:'DM Mono',monospace;--sans:'DM Sans','Noto Sans KR',sans-serif;--r:12px;--r2:20px;--shadow:0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04);--shadow2:0 4px 24px rgba(0,0,0,.10);}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{background:var(--bg);color:var(--txt);font-family:var(--sans);font-size:15px;line-height:1.65;min-height:100vh;display:flex;flex-direction:column;}

/* TOPNAV */
.topnav{display:flex;align-items:center;justify-content:space-between;padding:14px 32px;background:var(--white);border-bottom:1px solid var(--line);box-shadow:0 1px 4px rgba(0,0,0,.04);}
.logo{display:flex;align-items:center;gap:9px;font-weight:800;font-size:17px;color:var(--txt);text-decoration:none;}
.logo-dot{width:32px;height:32px;border-radius:8px;background:var(--blue);display:flex;align-items:center;justify-content:center;overflow:hidden;}
.logo-dot img{width:100%;height:100%;object-fit:contain;}
.logo em{color:var(--blue);font-style:normal;}
.chip{font-family:var(--mono);font-size:12px;padding:6px 14px;border-radius:999px;background:var(--white);border:1px solid var(--line);color:var(--txt2);cursor:pointer;transition:all .15s;text-decoration:none;display:inline-block;}
.chip:hover{border-color:var(--blue);color:var(--blue);}
.chip-blue{background:var(--blue);color:white;border-color:var(--blue);}
.chip-blue:hover{background:#1647c0;color:white;}

/* LOGIN MAIN - 더 넓게 */
.login-main{flex:1;display:flex;align-items:center;justify-content:center;padding:40px 20px;background:linear-gradient(135deg,#0f172a 0%,#0d6147 60%,#16a34a 100%);}
.login-card{background:var(--white);border-radius:var(--r2);padding:48px 52px;box-shadow:var(--shadow2);width:100%;max-width:560px;}

/* 로고 영역 */
.login-logo-wrap{text-align:center;margin-bottom:28px;}
.login-logo{width:52px;height:52px;border-radius:14px;background:var(--blue);display:flex;align-items:center;justify-content:center;margin:0 auto 14px;overflow:hidden;}
.login-logo img{width:100%;height:100%;object-fit:contain;}
.login-brand{font-size:22px;font-weight:800;letter-spacing:-.02em;color:var(--txt);margin-bottom:4px;}
.login-brand em{color:var(--blue);font-style:normal;}
.login-can{font-family:var(--mono);font-size:16px;font-weight:700;color:var(--blue);letter-spacing:.04em;margin-bottom:6px;}
.login-sub{font-size:14px;color:var(--txt3);}

/* 역할 그리드 (5개) */
.role-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:8px;margin-bottom:22px;}
.role-btn{border:1.5px solid var(--line);border-radius:var(--r);background:var(--white);color:var(--txt3);font-size:12px;font-weight:600;padding:10px 4px;text-align:center;cursor:pointer;transition:all .15s;font-family:var(--sans);}
.role-btn i{display:block;font-size:18px;margin-bottom:4px;}
.role-btn:hover{border-color:var(--blue);background:var(--blue-lt);color:var(--blue);}
.role-btn.active{border-color:var(--blue);background:var(--blue-lt);color:var(--blue);}
.role-btn-visitor{border-color:var(--teal)!important;color:var(--teal)!important;}
.role-btn-visitor:hover,.role-btn-visitor.active{background:var(--teal-lt)!important;color:var(--teal)!important;}

/* 알림 */
.alert-err{background:var(--red-lt);border:1.5px solid #fca5a5;border-radius:var(--r);color:var(--red);font-size:14px;font-weight:600;padding:12px 16px;margin-bottom:16px;display:flex;align-items:center;gap:8px;animation:shake .4s ease;}
.alert-ok{background:var(--green-lt);border:1.5px solid #86efac;border-radius:var(--r);color:var(--green);font-size:14px;padding:12px 16px;margin-bottom:16px;display:flex;align-items:center;gap:8px;}
@keyframes shake{0%,100%{transform:translateX(0)} 25%{transform:translateX(-6px)} 75%{transform:translateX(6px)}}

/* 폼 */
.f-label{font-family:var(--mono);font-size:12px;color:var(--txt2);display:block;margin-bottom:6px;font-weight:600;}
.f-wrap{position:relative;}
.f-icon{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:var(--txt3);font-size:15px;pointer-events:none;}
.f-input{width:100%;border:1.5px solid var(--line2);border-radius:var(--r);padding:12px 14px 12px 40px;font-size:15px;outline:none;background:var(--white);color:var(--txt);transition:border-color .15s,box-shadow .15s;}
.f-input:focus{border-color:var(--blue);box-shadow:0 0 0 3px var(--blue-lt);}
.f-input.is-error{border-color:var(--red)!important;box-shadow:0 0 0 3px #fee2e2!important;background:#fff5f5!important;}
.f-error-msg{display:flex;align-items:center;gap:5px;color:var(--red);font-size:13px;font-weight:600;margin-top:7px;animation:shake .4s ease;}
.f-error-msg i{font-size:15px;}
.f-pw-input{padding-right:42px;}
.f-eye{position:absolute;right:12px;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--txt3);cursor:pointer;padding:0;}

/* 버튼 */
.btn-prim{display:block;width:100%;text-align:center;background:var(--blue);color:white;border:none;border-radius:var(--r);padding:14px;font-size:16px;font-weight:700;cursor:pointer;transition:background .15s;}
.btn-prim:hover{background:#1647c0;}
.btn-ghost{display:block;width:100%;text-align:center;background:transparent;color:var(--txt2);border:1.5px solid var(--line2);border-radius:var(--r);padding:13px;font-size:14px;font-weight:600;cursor:pointer;transition:all .15s;text-decoration:none;}
.btn-ghost:hover{border-color:var(--blue);color:var(--blue);}
.btn-visitor{display:block;width:100%;text-align:center;background:var(--teal);color:white;border:none;border-radius:var(--r);padding:14px;font-size:16px;font-weight:700;cursor:pointer;text-decoration:none;margin-bottom:10px;}
.btn-visitor:hover{background:#0b7b70;color:white;}

/* 패널 전환 */
.staff-panel{display:block;}.staff-panel.hide{display:none;}
.visitor-panel{display:none;}.visitor-panel.show{display:block;}

/* 구분선 */
.divider{display:flex;align-items:center;gap:10px;margin:14px 0;font-size:12px;color:var(--txt3);}
.divider::before,.divider::after{content:'';flex:1;height:1px;background:var(--line);}

/* 힌트 */
.hint-box{background:var(--bg);border:1px solid var(--line);border-radius:var(--r);padding:14px 16px;margin-top:16px;}
.hint-hd{font-family:var(--mono);font-size:11px;color:var(--blue);text-transform:uppercase;letter-spacing:.1em;margin-bottom:10px;}
.hint-row{display:flex;justify-content:space-between;padding:5px 0;border-bottom:1px solid var(--line);font-size:13px;}
.hint-row:last-child{border-bottom:none;}
.hint-row .hk{font-weight:700;color:var(--txt);}
.hint-row .hv{font-family:var(--mono);font-size:12px;color:var(--blue);cursor:pointer;}

/* visitor info */
.visitor-info{background:var(--teal-lt);border:1.5px solid var(--teal-md);border-radius:var(--r);padding:14px 16px;margin-bottom:18px;font-size:14px;color:var(--teal);}

/* FOOTER */
.site-footer{border-top:1px solid var(--line);padding:18px 32px;background:var(--white);}
.footer-inner{max-width:1380px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;}
.footer-logo{display:flex;align-items:center;gap:8px;font-weight:800;font-size:14px;color:var(--txt);text-decoration:none;}
.footer-logo em{color:var(--blue);font-style:normal;}
.footer-team{font-family:var(--mono);font-size:12px;color:var(--txt3);text-align:center;line-height:1.8;}
.footer-team strong{color:var(--blue);}
.footer-copy{font-family:var(--mono);font-size:12px;color:var(--txt3);text-align:right;line-height:1.8;}
</style>
</head>
<body>

<nav class="topnav">
  <a href="/CAN/campuslogin.jsp" class="logo">
    <span class="logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>
    ICT <em>CAN</em>
  </a>
  <div style="display:flex;gap:8px">
    <a href="/CAN/search.jsp" class="chip"><i class="bi bi-search me-1"></i>검색</a>
    <a href="/CAN/register.jsp" class="chip chip-blue"><i class="bi bi-person-plus me-1"></i>회원가입</a>
  </div>
</nav>

<div class="login-main">
<div class="login-card">

  <div class="login-logo-wrap">
    <div class="login-logo"><img src="/CAN/images/logo.png" alt="ICT"></div>
    <div class="login-brand">ICT Campus Ai Nav<em>tor</em></div>
    <div class="login-can">ICT CAN</div>
    <div class="login-sub">교내 자원 내비게이션 시스템</div>
  </div>

  <!-- 역할 버튼 (5개 - 외부인 포함) -->
  <div class="role-grid">
    <button type="button" class="role-btn" id="btn-student" onclick="showStaff();fill('','',this,'student')">
      <i class="bi bi-mortarboard-fill"></i>학부생
    </button>
    <button type="button" class="role-btn" id="btn-assist" onclick="showStaff();fill('','',this,'assistant')">
      <i class="bi bi-person-workspace"></i>조교
    </button>
    <button type="button" class="role-btn" id="btn-prof" onclick="showStaff();fill('','',this,'professor')">
      <i class="bi bi-person-badge-fill"></i>교수
    </button>
    <button type="button" class="role-btn" id="btn-admin" onclick="showStaff();fill('','',this,'admin')">
      <i class="bi bi-shield-fill"></i>관리자
    </button>
    <button type="button" class="role-btn role-btn-visitor" id="btn-visitor" onclick="showVisitor(this)">
      <i class="bi bi-person-walking"></i>외부인
    </button>
  </div>

  <!-- 에러/성공 -->
  <% if("true".equals(registered)){%><div class="alert-ok"><i class="bi bi-check-circle-fill"></i>회원가입 완료! 로그인해 주세요.</div><%}%>

  <!-- 재학생/교직원 패널 -->
  <div class="staff-panel" id="staffPanel">
    <form action="/CAN/login" method="post" id="frm">
      <input type="hidden" id="selectedRole" name="selectedRole" value="">
      <div style="margin-bottom:14px">
        <label class="f-label">학번 / 아이디</label>
        <div class="f-wrap">
          <i class="bi bi-person f-icon"></i>
          <input class="f-input<%= !errorMsg.isEmpty() ? " is-error" : "" %>" type="text" id="userId" name="userId" placeholder="아이디 입력" value="<%= prevId %>" autocomplete="username">
        </div>
      </div>
      <div style="margin-bottom:16px">
        <label class="f-label">비밀번호</label>
        <div class="f-wrap">
          <i class="bi bi-lock f-icon"></i>
          <input class="f-input f-pw-input<%= !errorMsg.isEmpty() ? " is-error" : "" %>" type="password" id="pwField" name="userPw" placeholder="비밀번호 입력" autocomplete="current-password">
          <button type="button" class="f-eye" onclick="togglePw()"><i class="bi bi-eye" id="eyeIco"></i></button>
        </div>
        <% if(!errorMsg.isEmpty()){ %>
        <div class="f-error-msg"><i class="bi bi-exclamation-circle-fill"></i><%= errorMsg %></div>
        <% } %>
      </div>
      <div class="d-flex justify-content-between align-items-center" style="margin-bottom:20px">
        <label style="display:flex;align-items:center;gap:6px;font-size:13px;color:var(--txt2);cursor:pointer">
          <input type="checkbox" name="saveId" style="accent-color:var(--blue)"> 아이디 저장
        </label>
      </div>
      <button type="submit" class="btn-prim"><i class="bi bi-compass me-1"></i>로그인</button>
    </form>
    <div class="divider">또는</div>
    <a href="/CAN/register.jsp" class="btn-ghost" style="margin-bottom:8px"><i class="bi bi-person-plus me-1"></i>회원가입</a>
    <a href="/CAN/guest" style="display:block;text-align:center;font-size:13px;color:var(--txt3);text-decoration:none;padding:10px;border:1.5px dashed var(--line2);border-radius:var(--r);transition:all .15s" onmouseover="this.style.borderColor='var(--blue)';this.style.color='var(--blue)'" onmouseout="this.style.borderColor='var(--line2)';this.style.color='var(--txt3)'">
      <i class="bi bi-eye me-1"></i>로그인 없이 둘러보기 (게스트)
    </a>
    <div class="hint-box">
      <div class="hint-hd">테스트 계정 (DB 등록된 계정)</div>
      <div class="hint-row"><span class="hk">회원가입</span><span style="font-size:12px;color:var(--txt3)">→ 직접 계정 생성 후 로그인</span></div>
    </div>
  </div>

  <!-- 외부인 패널 -->
  <div class="visitor-panel" id="visitorPanel">
    <div style="text-align:center;padding:16px 0 20px">
      <div style="font-size:52px;margin-bottom:14px">🏫</div>
      <div style="font-size:18px;font-weight:800;margin-bottom:8px">외부 방문자이신가요?</div>
      <div style="font-size:14px;color:var(--txt3);line-height:1.8">별도 계정 없이 바로 입장하세요.</div>
    </div>
    <div class="visitor-info">
      <div style="margin-bottom:6px"><i class="bi bi-check-circle-fill me-1"></i><strong>이용 가능:</strong> 공간 예약, 캠퍼스 길찾기</div>
      <div><i class="bi bi-x-circle-fill me-1"></i><strong style="color:var(--red)">이용 불가:</strong> 자원 검색, 자산 상세 조회</div>
    </div>
    <a href="/CAN/visitor" class="btn-visitor"><i class="bi bi-door-open me-1"></i>외부인으로 입장하기</a>
    <button type="button" class="btn-ghost" onclick="showStaff()"><i class="bi bi-arrow-left me-1"></i>재학생·교직원 로그인으로 돌아가기</button>
  </div>

</div>
</div>

<footer class="site-footer">
  <div class="footer-inner">
    <a href="/CAN/campuslogin.jsp" class="footer-logo"><span style="width:22px;height:22px;border-radius:6px;background:var(--blue);display:flex;align-items:center;justify-content:center;overflow:hidden"><img src="/CAN/images/logo.png" alt="ICT" style="width:100%;height:100%;object-fit:contain"></span>ICT <em>CAN</em></a>
    <div class="footer-team"><strong>Made by AI 소프트웨어학과</strong><br>박승순 &middot; 권동해 &middot; 원태연 &middot; 이수혁</div>
    <div class="footer-copy">ICT폴리텍대학 교내 자원 내비게이션 시스템<br>Copyright &copy; 2026 ICT CAN. All rights reserved.</div>
  </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function showVisitor(btn){
  document.getElementById('staffPanel').classList.add('hide');
  document.getElementById('visitorPanel').classList.add('show');
  document.querySelectorAll('.role-btn').forEach(function(b){b.classList.remove('active');});
  if(btn)btn.classList.add('active');
  var r=document.getElementById('selectedRole');
  if(r)r.value='';
}
function showStaff(){
  document.getElementById('staffPanel').classList.remove('hide');
  document.getElementById('visitorPanel').classList.remove('show');
  // active 클래스 제거만, selectedRole 건드리지 않음
  document.querySelectorAll('.role-btn').forEach(function(b){b.classList.remove('active');});
}
function fill(id,pw,btn,role){
  var u=document.getElementById('userId'),p=document.getElementById('pwField');
  if(u&&id)u.value=id; if(p&&pw)p.value=pw;
  document.querySelectorAll('.role-btn').forEach(function(b){b.classList.remove('active');});
  if(btn)btn.classList.add('active');
  var r=document.getElementById('selectedRole');
  if(r)r.value=role||'';
}
function togglePw(){
  var pw=document.getElementById('pwField'),ic=document.getElementById('eyeIco');
  if(!pw)return;
  if(pw.type==='password'){pw.type='text';ic.className='bi bi-eye-slash';}
  else{pw.type='password';ic.className='bi bi-eye';}
}
var frm=document.getElementById('frm');
if(frm){frm.addEventListener('submit',function(e){
  if(!document.getElementById('userId').value.trim()||!document.getElementById('pwField').value.trim()){
    e.preventDefault();alert('아이디와 비밀번호를 입력해 주세요.');
  }
});}
</script>
</body>
</html>
