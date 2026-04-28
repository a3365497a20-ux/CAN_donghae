<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         session="true" import="java.sql.*,java.util.*" %>
<%
    String loginUser = (String)session.getAttribute("loginUser");
    String loginName = (String)session.getAttribute("loginName");
    String loginRole = (String)session.getAttribute("loginRole");
    if(loginUser == null){ response.sendRedirect("/CAN/campuslogin.jsp"); return; }
    if("guest".equals(loginRole)){ response.sendRedirect("/CAN/main_guest.jsp"); return; }

    // 파라미터
    String selType   = request.getParameter("type");   if(selType  == null) selType  = "강의실";
    String roomIdStr = request.getParameter("roomId"); if(roomIdStr== null) roomIdStr= "";
    String success   = request.getParameter("success");if(success  == null) success  = "";
    String errMsg    = request.getParameter("err");    if(errMsg   == null) errMsg   = "";

    // POST 처리
    if("POST".equals(request.getMethod())){
        String postRoomId = request.getParameter("roomId");
        String rDate      = request.getParameter("date");
        String rStart     = request.getParameter("startTime");
        String rEnd       = request.getParameter("endTime");
        String purpose    = request.getParameter("purpose");
        String phone      = request.getParameter("phone");
        String postType   = request.getParameter("type"); if(postType==null) postType="강의실";

        if(postRoomId!=null && !postRoomId.isEmpty() && rDate!=null && !rDate.isEmpty()
                && rStart!=null && rEnd!=null){
            try{
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/campusnav?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8&allowPublicKeyRetrieval=true","root","1234");

                // 중복 체크
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM room_reservations WHERE room_id=? AND reserve_date=? AND status='예약완료' AND start_time<? AND end_time>?");
                ps.setInt(1, Integer.parseInt(postRoomId));
                ps.setString(2, rDate); ps.setString(3, rEnd); ps.setString(4, rStart);
                ResultSet rs = ps.executeQuery();
                boolean dup = rs.next() && rs.getInt(1) > 0;
                rs.close(); ps.close();

                if(dup){
                    response.sendRedirect("/CAN/room_reserve.jsp?type="+java.net.URLEncoder.encode(postType,"UTF-8")+"&roomId="+postRoomId+"&err=이미+예약된+시간입니다");
                } else {
                    ps = conn.prepareStatement(
                        "INSERT INTO room_reservations(room_id,user_id,reserve_date,start_time,end_time,purpose,phone,status) VALUES(?,?,?,?,?,?,?,'예약완료')");
                    ps.setInt(1, Integer.parseInt(postRoomId));
                    ps.setString(2, loginUser);
                    ps.setString(3, rDate); ps.setString(4, rStart); ps.setString(5, rEnd);
                    ps.setString(6, purpose!=null?purpose:"");
                    ps.setString(7, phone!=null?phone:"");
                    ps.executeUpdate(); ps.close();
                    response.sendRedirect("/CAN/room_reserve.jsp?type="+java.net.URLEncoder.encode(postType,"UTF-8")+"&roomId="+postRoomId+"&success=true");
                }
                conn.close();
            } catch(Exception e){
                response.sendRedirect("/CAN/room_reserve.jsp?type="+java.net.URLEncoder.encode(selType,"UTF-8")
                    +"&roomId="+postRoomId+"&err="+java.net.URLEncoder.encode(e.getMessage(),"UTF-8"));
            }
            return;
        }
    }

    // 방 목록 조회
    List<Map<String,String>> rooms = new ArrayList<>();
    Map<String,String> selRoom = null;
    List<Map<String,String>> existReserves = new ArrayList<>();

    try{
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/campusnav?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8&allowPublicKeyRetrieval=true","root","1234");

        // 선택된 타입의 방 목록
        PreparedStatement ps = conn.prepareStatement(
            "SELECT room_id,room_name,room_type,building,floor,room_no,capacity,description FROM rooms WHERE room_type=? AND is_active='Y' ORDER BY floor,room_no");
        ps.setString(1, selType);
        ResultSet rs = ps.executeQuery();
        while(rs.next()){
            Map<String,String> r = new LinkedHashMap<>();
            r.put("id",       String.valueOf(rs.getInt("room_id")));
            r.put("name",     rs.getString("room_name"));
            r.put("type",     rs.getString("room_type"));
            r.put("building", rs.getString("building"));
            r.put("floor",    String.valueOf(rs.getInt("floor")));
            r.put("no",       rs.getString("room_no"));
            r.put("cap",      String.valueOf(rs.getInt("capacity")));
            r.put("desc",     rs.getString("description")!=null?rs.getString("description"):"");
            rooms.add(r);
            if(r.get("id").equals(roomIdStr)) selRoom = r;
        }
        rs.close(); ps.close();

        // 선택된 방의 기존 예약
        if(selRoom != null){
            ps = conn.prepareStatement(
                "SELECT reserve_date,start_time,end_time,user_id FROM room_reservations WHERE room_id=? AND reserve_date>=CURDATE() AND status='예약완료' ORDER BY reserve_date,start_time LIMIT 20");
            ps.setInt(1, Integer.parseInt(roomIdStr));
            rs = ps.executeQuery();
            while(rs.next()){
                Map<String,String> rv = new LinkedHashMap<>();
                rv.put("date",  rs.getString(1));
                rv.put("start", rs.getString(2));
                rv.put("end",   rs.getString(3));
                rv.put("user",  rs.getString(4));
                existReserves.add(rv);
            }
            rs.close(); ps.close();
        }
        conn.close();
    } catch(Exception ignored){}

    String today = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    String roleLabel = "student".equals(loginRole)?"학부생":"assistant".equals(loginRole)?"조교":"professor".equals(loginRole)?"교수":"관리자";
%>
<!DOCTYPE html><html lang="ko"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>ICT CAN — 강의실 예약</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,700;9..40,800&family=DM+Mono:wght@400;500&family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/CAN/css/common.css">
<style>
:root{
  --white:#fff;--bg:#f7f8fa;--bg2:#f0f2f5;
  --line:#e4e7ed;--line2:#d0d5df;
  --txt:#111827;--txt2:#4b5563;--txt3:#9ca3af;
  --blue:#1a56db;--blue-lt:#eff4ff;--blue-md:#c7d7fd;
  --teal:#0d9488;--teal-lt:#f0fdfa;--teal-md:#99f6e4;
  --amber:#d97706;--amber-lt:#fffbeb;
  --red:#dc2626;--red-lt:#fef2f2;
  --green:#16a34a;--green-lt:#f0fdf4;
  --purple:#7c3aed;--purple-lt:#f5f3ff;
  --mono:'DM Mono',monospace;--sans:'DM Sans','Noto Sans KR',sans-serif;
  --r:12px;--r2:20px;
  --shadow:0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.04);
  --shadow2:0 2px 8px rgba(0,0,0,.08),0 12px 32px rgba(0,0,0,.06);
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{background:var(--bg);color:var(--txt);font-family:var(--sans);font-size:15px;line-height:1.65;}

.topnav{display:flex;align-items:center;justify-content:space-between;padding:14px 28px;background:var(--white);border-bottom:1px solid var(--line);position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.04);}
.logo{display:flex;align-items:center;gap:10px;font-weight:800;font-size:17px;color:var(--txt);text-decoration:none;}
.logo-dot{width:32px;height:32px;border-radius:8px;background:var(--blue);display:flex;align-items:center;justify-content:center;overflow:hidden;}
.logo-dot img{width:100%;height:100%;object-fit:contain;}
.logo em{color:var(--blue);font-style:normal;}
.nav-right{display:flex;gap:8px;align-items:center;}
.chip{font-family:var(--mono);font-size:13px;padding:6px 14px;border-radius:999px;background:var(--white);border:1px solid var(--line);color:var(--txt2);cursor:pointer;transition:all .15s;text-decoration:none;display:inline-block;}
.chip:hover{border-color:var(--blue);color:var(--blue);}
.role-chip{font-family:var(--mono);font-size:12px;padding:5px 13px;border-radius:6px;background:var(--blue-lt);border:1px solid var(--blue-md);color:var(--blue);}

.shell{max-width:1300px;margin:0 auto;padding:28px 28px 72px;}

/* HERO */
.hero{background:linear-gradient(135deg,#0f172a 0%,#1e3a5f 50%,#1a56db 100%);border-radius:var(--r2);padding:36px 44px;margin-bottom:24px;box-shadow:0 8px 32px rgba(15,23,42,.25);display:grid;grid-template-columns:1fr auto;gap:32px;align-items:center;position:relative;overflow:hidden;}
.hero::after{content:'';position:absolute;right:0;top:0;bottom:0;width:260px;background:linear-gradient(135deg,rgba(255,255,255,.06) 0%,rgba(26,86,219,.18) 100%);clip-path:polygon(15% 0%,100% 0%,100% 100%,0% 100%);z-index:0;pointer-events:none;}
.hero-content{position:relative;z-index:1;}
.hero-eyebrow{font-family:var(--mono);font-size:12px;color:rgba(255,255,255,.7);letter-spacing:.14em;text-transform:uppercase;margin-bottom:10px;}
.hero-title{font-size:28px;font-weight:800;color:#fff;letter-spacing:-.03em;margin-bottom:8px;}
.hero-title em{color:#93c5fd;font-style:normal;}
.hero-desc{color:rgba(255,255,255,.8);font-size:14px;line-height:1.7;}
.hero-side{position:relative;z-index:2;font-size:52px;line-height:1;}

/* TYPE TABS */
.type-tabs{display:flex;gap:10px;margin-bottom:24px;flex-wrap:wrap;}
.type-tab{display:flex;align-items:center;gap:8px;padding:11px 22px;border-radius:var(--r2);border:2px solid var(--line);background:var(--white);font-size:15px;font-weight:700;color:var(--txt2);cursor:pointer;text-decoration:none;transition:all .18s;box-shadow:var(--shadow);}
.type-tab:hover{border-color:var(--blue);color:var(--blue);}
.type-tab.active{background:var(--blue);border-color:var(--blue);color:#fff;box-shadow:0 4px 16px rgba(26,86,219,.25);}
.type-tab .icon{font-size:20px;}
.type-tab .cnt{font-family:var(--mono);font-size:12px;padding:2px 8px;border-radius:999px;background:rgba(255,255,255,.25);margin-left:2px;}
.type-tab:not(.active) .cnt{background:var(--bg2);color:var(--txt3);}

/* LAYOUT */
.layout{display:grid;grid-template-columns:320px 1fr;gap:20px;align-items:start;}

/* ROOM LIST */
.room-list-card{background:var(--white);border:1.5px solid var(--line2);border-radius:var(--r2);box-shadow:var(--shadow);overflow:hidden;}
.room-list-head{padding:16px 20px;border-bottom:1.5px solid var(--line2);background:var(--bg);display:flex;align-items:center;gap:10px;}
.room-list-title{font-size:14px;font-weight:800;color:var(--txt);}
.room-item{display:flex;align-items:center;gap:14px;padding:14px 18px;border-bottom:1px solid var(--line);cursor:pointer;transition:background .12s;text-decoration:none;color:var(--txt);}
.room-item:last-child{border-bottom:none;}
.room-item:hover{background:var(--blue-lt);}
.room-item.selected{background:var(--blue-lt);border-left:3px solid var(--blue);}
.room-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
.ri-강의실{background:var(--blue-lt);}
.ri-컴퓨터실{background:var(--teal-lt);}
.ri-세미나실{background:var(--purple-lt);}
.room-name{font-size:14px;font-weight:700;color:var(--txt);}
.room-meta{font-size:12px;color:var(--txt3);font-family:var(--mono);margin-top:2px;}
.room-cap{font-family:var(--mono);font-size:12px;padding:3px 9px;border-radius:6px;background:var(--bg2);color:var(--txt2);margin-left:auto;flex-shrink:0;}

/* CARD */
.card{background:var(--white);border:1.5px solid var(--line2);border-radius:var(--r2);box-shadow:var(--shadow);overflow:hidden;margin-bottom:20px;}
.card-head{padding:16px 22px;border-bottom:1.5px solid var(--line2);display:flex;align-items:center;gap:12px;background:var(--bg);}
.ch-icon{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
.si-blue{background:var(--blue-lt);}
.si-amber{background:var(--amber-lt);}
.ch-title{font-size:15px;font-weight:800;color:var(--txt);}
.ch-sub{font-size:12px;color:var(--txt3);margin-top:2px;}
.card-body{padding:20px 22px;}

/* FORM */
.f-label{font-family:var(--mono);font-size:12px;color:var(--txt2);display:block;margin-bottom:6px;font-weight:500;}
.f-input{width:100%;border:1.5px solid var(--line2);border-radius:var(--r);padding:10px 13px;font-size:14px;outline:none;background:var(--white);color:var(--txt);font-family:var(--sans);transition:border-color .15s;}
.f-input:focus{border-color:var(--blue);box-shadow:0 0 0 3px var(--blue-lt);}
.btn-prim{display:inline-block;text-align:center;background:var(--blue);color:white;border:none;border-radius:var(--r);padding:11px 20px;font-size:14px;font-weight:700;cursor:pointer;transition:background .15s;text-decoration:none;}
.btn-prim:hover{background:#1647c0;color:white;}
.time-check{margin-top:8px;padding:10px 14px;border-radius:var(--r);font-size:13px;font-weight:600;display:none;}
.time-ok{background:var(--green-lt);border:1px solid #86efac;color:var(--green);}
.time-err{background:var(--red-lt);border:1px solid #fca5a5;color:var(--red);}

/* ALERTS */
.alert-err{background:var(--red-lt);border:1px solid #fca5a5;border-radius:var(--r);color:var(--red);font-size:13px;padding:11px 14px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
.alert-ok{background:var(--green-lt);border:1px solid #86efac;border-radius:var(--r);color:var(--green);font-size:13px;padding:11px 14px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}

/* ROOM INFO BOX */
.room-info-box{background:var(--blue-lt);border:1.5px solid var(--blue-md);border-radius:var(--r);padding:14px 18px;margin-bottom:18px;display:flex;align-items:center;gap:14px;}
.rib-icon{font-size:28px;}
.rib-name{font-size:16px;font-weight:800;color:var(--blue);}
.rib-meta{font-size:13px;color:var(--txt2);margin-top:2px;}

/* EMPTY STATE */
.empty-state{text-align:center;padding:40px 20px;color:var(--txt3);}
.empty-icon{font-size:36px;display:block;margin-bottom:10px;opacity:.5;}
.empty-text{font-size:14px;line-height:1.7;}

/* FOOTER */
.site-footer{margin-top:60px;border-top:1px solid var(--line);padding:28px 0 40px;}
.footer-inner{max-width:1300px;margin:0 auto;padding:0 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px;}
.footer-logo{display:flex;align-items:center;gap:10px;font-weight:800;font-size:15px;color:var(--txt);text-decoration:none;}
.footer-logo em{color:var(--blue);font-style:normal;}
.footer-logo-dot{width:26px;height:26px;border-radius:7px;background:var(--blue);display:flex;align-items:center;justify-content:center;overflow:hidden;}
.footer-logo-dot img{width:100%;height:100%;object-fit:contain;}
.footer-copy{font-family:var(--mono);font-size:12px;color:var(--txt3);text-align:right;line-height:1.8;}

@media(max-width:900px){.layout{grid-template-columns:1fr;}.hero{grid-template-columns:1fr;}.hero-side{display:none;}}
</style>
</head><body>

<!-- TOPNAV -->
<div class="topnav">
  <a href="/CAN/main_<%= loginRole %>.jsp" class="logo">
    <span class="logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>
    ICT <em>CAN</em>
  </a>
  <div class="nav-right">
    <span style="font-family:var(--mono);font-size:13px;color:var(--txt2)"><i class="bi bi-person-circle me-1"></i><%= loginName %></span>
    <span class="role-chip"><%= roleLabel %></span>
    <a href="/CAN/main_<%= loginRole %>.jsp" class="chip"><i class="bi bi-house me-1"></i>홈</a>
    <form action="/CAN/logout" method="post" style="margin:0"><button type="submit" class="chip"><i class="bi bi-box-arrow-right me-1"></i>로그아웃</button></form>
  </div>
</div>

<div class="shell">

<!-- HERO -->
<div class="hero">
  <div class="hero-content">
    <div class="hero-eyebrow">ICT CAN · 강의실 예약</div>
    <div class="hero-title">강의실 · 세미나실 · <em>컴퓨터실</em> 예약</div>
    <div class="hero-desc">제1공학관 내 강의실, 세미나실, 컴퓨터실을 예약할 수 있습니다.<br>방을 선택하고 원하는 날짜와 시간을 입력하세요.</div>
  </div>
  <div class="hero-side">🏫</div>
</div>

<!-- 알림 -->
<% if(!success.isEmpty()){%>
<div class="alert-ok"><i class="bi bi-check-circle-fill"></i>예약이 완료되었습니다!</div>
<%}%>
<% if(!errMsg.isEmpty()){%>
<div class="alert-err"><i class="bi bi-exclamation-circle-fill"></i><%= errMsg %></div>
<%}%>

<!-- 타입 탭 -->
<div class="type-tabs">
  <a href="/CAN/room_reserve.jsp?type=강의실"   class="type-tab <%= "강의실".equals(selType)?"active":"" %>">
    <span class="icon">🏫</span> 강의실 <span class="cnt">9</span>
  </a>
  <a href="/CAN/room_reserve.jsp?type=컴퓨터실" class="type-tab <%= "컴퓨터실".equals(selType)?"active":"" %>">
    <span class="icon">💻</span> 컴퓨터실 <span class="cnt">7</span>
  </a>
  <a href="/CAN/room_reserve.jsp?type=세미나실" class="type-tab <%= "세미나실".equals(selType)?"active":"" %>">
    <span class="icon">🪑</span> 세미나실 <span class="cnt">2</span>
  </a>
</div>

<!-- 메인 레이아웃 -->
<div class="layout">

  <!-- 왼쪽: 방 목록 -->
  <div class="room-list-card">
    <div class="room-list-head">
      <i class="bi bi-door-open" style="color:var(--blue)"></i>
      <span class="room-list-title"><%= selType %> 목록 — 제1공학관</span>
    </div>
    <% if(rooms.isEmpty()){ %>
    <div class="empty-state">
      <span class="empty-icon"><i class="bi bi-inbox"></i></span>
      <div class="empty-text">등록된 방이 없습니다.</div>
    </div>
    <% } else { for(Map<String,String> r : rooms) {
        boolean isSel = r.get("id").equals(roomIdStr);
        String iconEmoji = "강의실".equals(selType)?"🏫":"컴퓨터실".equals(selType)?"💻":"🪑";
        String riClass   = "ri-" + selType;
    %>
    <a href="/CAN/room_reserve.jsp?type=<%= java.net.URLEncoder.encode(selType,"UTF-8") %>&roomId=<%= r.get("id") %>"
       class="room-item <%= isSel?"selected":"" %>">
      <div class="room-icon <%= riClass %>"><%= iconEmoji %></div>
      <div style="flex:1;min-width:0;">
        <div class="room-name"><%= r.get("name") %></div>
        <div class="room-meta"><%= r.get("floor") %>층 · <%= r.get("desc") %></div>
      </div>
      <div class="room-cap"><i class="bi bi-people-fill me-1"></i><%= r.get("cap") %>명</div>
    </a>
    <% }} %>
  </div>

  <!-- 오른쪽: 예약 폼 + 기존 예약 -->
  <div>
    <% if(selRoom == null) { %>
    <div class="card">
      <div class="card-body">
        <div class="empty-state">
          <span class="empty-icon"><i class="bi bi-hand-index"></i></span>
          <div class="empty-text">왼쪽 목록에서 예약할 방을 선택하세요.</div>
        </div>
      </div>
    </div>
    <% } else { %>

    <!-- 선택된 방 정보 -->
    <div class="room-info-box">
      <div class="rib-icon"><%= "강의실".equals(selType)?"🏫":"컴퓨터실".equals(selType)?"💻":"🪑" %></div>
      <div>
        <div class="rib-name"><%= selRoom.get("name") %></div>
        <div class="rib-meta">
          <i class="bi bi-building me-1"></i><%= selRoom.get("building") %>
          &nbsp;·&nbsp;<%= selRoom.get("floor") %>층
          &nbsp;·&nbsp;<i class="bi bi-people-fill me-1"></i>수용 <%= selRoom.get("cap") %>명
          &nbsp;·&nbsp;<%= selRoom.get("desc") %>
        </div>
      </div>
    </div>

    <div class="row g-4">
    <!-- 예약 폼 -->
    <div class="col-lg-7">
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-blue"><i class="bi bi-calendar-plus" style="color:var(--blue)"></i></div>
        <div><div class="ch-title">예약 정보 입력</div><div class="ch-sub"><%= selRoom.get("name") %></div></div>
      </div>
      <div class="card-body">
      <form method="post" action="/CAN/room_reserve.jsp" onsubmit="return checkBefore()">
        <input type="hidden" name="roomId" value="<%= selRoom.get("id") %>">
        <input type="hidden" name="type"   value="<%= selType %>">

        <div style="margin-bottom:16px">
          <label class="f-label">예약 날짜 *</label>
          <input class="f-input" type="date" name="date" id="rDate" required min="<%= today %>" onchange="checkTime()">
        </div>
        <div class="row g-3" style="margin-bottom:16px">
          <div class="col-6">
            <label class="f-label">시작 시간 *</label>
            <input class="f-input" type="time" name="startTime" id="rStart" required onchange="checkTime()">
          </div>
          <div class="col-6">
            <label class="f-label">종료 시간 *</label>
            <input class="f-input" type="time" name="endTime" id="rEnd" required onchange="checkTime()">
          </div>
        </div>
        <div id="timeCheck" class="time-check"></div>
        <div style="margin-bottom:16px">
          <label class="f-label">사용 목적</label>
          <input class="f-input" type="text" name="purpose" placeholder="예) 캡스톤 프로젝트 회의">
        </div>
        <div style="margin-bottom:20px">
          <label class="f-label">연락처</label>
          <input class="f-input" type="text" name="phone" placeholder="010-0000-0000">
        </div>
        <button type="submit" class="btn-prim" style="width:100%;padding:13px;font-size:15px">
          <i class="bi bi-check-circle me-1"></i>예약 신청
        </button>
      </form>
      </div>
    </div>
    </div>

    <!-- 기존 예약 현황 -->
    <div class="col-lg-5">
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-amber"><i class="bi bi-clock-history" style="color:var(--amber)"></i></div>
        <div><div class="ch-title">기존 예약 현황</div><div class="ch-sub"><%= existReserves.size() %>건 예약 중</div></div>
      </div>
      <div class="card-body">
        <% if(existReserves.isEmpty()){ %>
        <div style="text-align:center;padding:20px;color:var(--txt3)">
          <i class="bi bi-check-circle" style="font-size:26px;display:block;margin-bottom:8px;color:var(--green);opacity:.6"></i>
          <div style="font-size:13px">예약 내역이 없습니다.<br>이 방은 예약 가능합니다!</div>
        </div>
        <% } else { for(Map<String,String> rv : existReserves){ %>
        <div style="border:1px solid #fca5a5;border-radius:var(--r);padding:10px 14px;margin-bottom:8px;background:var(--red-lt)">
          <div style="font-weight:700;color:var(--red);font-size:13px"><i class="bi bi-x-circle me-1"></i><%= rv.get("date") %></div>
          <div style="font-size:14px;font-weight:600"><%= rv.get("start") %> ~ <%= rv.get("end") %></div>
          <div style="font-size:12px;color:var(--txt3)">예약자: <%= rv.get("user") %></div>
        </div>
        <% }} %>
      </div>
    </div>
    </div>
    </div><!-- row -->

    <% } %>
  </div><!-- 오른쪽 -->
</div><!-- layout -->

</div><!-- shell -->

<footer class="site-footer">
  <div class="footer-inner">
    <a href="/CAN/campuslogin.jsp" class="footer-logo">
      <span class="footer-logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>
      ICT <em>CAN</em>
    </a>
    <div style="font-family:var(--mono);font-size:12px;color:var(--txt3);text-align:center;line-height:1.8">
      <strong style="color:var(--blue);font-size:13px">Made by AI 소프트웨어학과</strong><br>
      박승순 &nbsp;&middot;&nbsp; 권동해 &nbsp;&middot;&nbsp; 원태연 &nbsp;&middot;&nbsp; 이수혁
    </div>
    <div class="footer-copy">
      ICT폴리텍대학<br>교내 자원 내비게이션 시스템<br>
      Copyright &copy; 2026 ICT CAN. All rights reserved.
    </div>
  </div>
</footer>

<script>
var er = [<% for(int i=0;i<existReserves.size();i++){Map<String,String> rv=existReserves.get(i); %>
  {date:"<%= rv.get("date") %>",start:"<%= rv.get("start") %>",end:"<%= rv.get("end") %>"}<%=i<existReserves.size()-1?",":"" %>
<% } %>];

function checkTime(){
  var date=document.getElementById('rDate').value,
      start=document.getElementById('rStart').value,
      end=document.getElementById('rEnd').value,
      el=document.getElementById('timeCheck');
  if(!date||!start||!end){el.style.display='none';return;}
  if(start>=end){
    el.className='time-check time-err';
    el.innerHTML='<i class="bi bi-x-circle-fill me-1"></i>종료 시간이 시작 시간보다 빠릅니다.';
    el.style.display='block';return;
  }
  var c=null;
  for(var r of er){if(r.date===date&&start<r.end&&end>r.start){c=r;break;}}
  if(c){
    el.className='time-check time-err';
    el.innerHTML='<i class="bi bi-x-circle-fill me-1"></i><strong>예약 불가!</strong> '+c.start+'~'+c.end+' 이미 예약되어 있습니다.';
  } else {
    el.className='time-check time-ok';
    el.innerHTML='<i class="bi bi-check-circle-fill me-1"></i><strong>예약 가능!</strong> 선택하신 시간에 예약할 수 있습니다.';
  }
  el.style.display='block';
}
function checkBefore(){
  var el=document.getElementById('timeCheck');
  if(el&&el.classList.contains('time-err')){alert('예약 불가능한 시간입니다.');return false;}
  return true;
}
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body></html>
