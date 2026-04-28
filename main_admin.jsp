<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" import="java.sql.*,java.util.*" %>
<%
    String loginUser=(String)session.getAttribute("loginUser");
    String loginName=(String)session.getAttribute("loginName");
    if(loginUser==null){response.sendRedirect("/CAN/campuslogin.jsp");return;}
    if(!"admin".equals(session.getAttribute("loginRole"))){response.sendRedirect("/CAN/campuslogin.jsp");return;}

    final String DBURL="jdbc:mysql://localhost:3306/campusnav?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8&allowPublicKeyRetrieval=true";

    String okMsg="",errMsg="";
    // ── POST 처리 ──
    if("POST".equals(request.getMethod())){
        request.setCharacterEncoding("UTF-8");
        String act=request.getParameter("act");
        // 예약 연장
        if("extendReserve".equals(act)){
            String rid=request.getParameter("reserveId");
            String extendHours=request.getParameter("extendHours");
            try{
                int hours=Integer.parseInt(extendHours!=null?extendHours:"1");
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection c=DriverManager.getConnection(DBURL,"root","1234");
                PreparedStatement ps=c.prepareStatement("UPDATE reservations SET end_time=DATE_ADD(end_time,INTERVAL ? HOUR) WHERE reserve_id=?");
                ps.setInt(1,hours);ps.setString(2,rid);int n=ps.executeUpdate();ps.close();c.close();
                okMsg=n>0?"예약 #"+rid+" 이(가) "+hours+"시간 연장되었습니다":"해당 예약을 찾을 수 없습니다.";
            }catch(Exception e){errMsg="연장 오류: "+e.getMessage();}
        }
        // 예약 취소
        else if("cancelReserve".equals(act)){
            String rid=request.getParameter("reserveId");
            try{
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection c=DriverManager.getConnection(DBURL,"root","1234");
                PreparedStatement ps=c.prepareStatement("UPDATE reservations SET status='취소' WHERE reserve_id=?");
                ps.setString(1,rid);int n=ps.executeUpdate();ps.close();c.close();
                okMsg=n>0?"예약 #"+rid+" 취소 완료":"해당 예약을 찾을 수 없습니다.";
            }catch(Exception e){errMsg="취소 오류: "+e.getMessage();}
        }
        // 이관내역 등록
        else if("addTransfer".equals(act)){
            String assetNo=request.getParameter("t_asset_no");
            String tDate=request.getParameter("t_date");
            String fDept=request.getParameter("t_from_dept");
            String fLoc=request.getParameter("t_from_loc");
            String tDept=request.getParameter("t_to_dept");
            String tLoc=request.getParameter("t_to_loc");
            String rmk=request.getParameter("t_remark");
            if(assetNo==null||assetNo.trim().isEmpty()||tDate==null||tDate.trim().isEmpty()){
                errMsg="자산번호와 이관일자는 필수입니다.";
            } else {
                try{
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection c=DriverManager.getConnection(DBURL,"root","1234");
                    // 자산 존재 확인
                    PreparedStatement ck=c.prepareStatement("SELECT item_name FROM assets WHERE asset_no=?");
                    ck.setString(1,assetNo.trim());ResultSet rck=ck.executeQuery();
                    if(!rck.next()){errMsg="자산번호 ["+assetNo+"] 이(가) 없습니다.";}
                    else{
                        String iname=rck.getString(1);rck.close();ck.close();
                        PreparedStatement ps=c.prepareStatement(
                            "INSERT INTO asset_transfer(asset_no,item_name,transfer_date,before_dept,before_detail,after_dept,after_detail,remark) VALUES(?,?,?,?,?,?,?,?)");
                        ps.setString(1,assetNo.trim());ps.setString(2,iname);
                        ps.setString(3,tDate.trim());ps.setString(4,fDept!=null?fDept:"");
                        ps.setString(5,fLoc!=null?fLoc:"");ps.setString(6,tDept!=null?tDept:"");
                        ps.setString(7,tLoc!=null?tLoc:"");ps.setString(8,rmk!=null?rmk:"");
                        ps.executeUpdate();ps.close();
                        okMsg="이관내역 등록 완료! ["+assetNo+"] "+iname;
                    }
                    c.close();
                }catch(Exception e){errMsg="이관 등록 오류: "+e.getMessage();}
            }
        }
    }

    // ── 통계 조회 ──
    int tA=0,tT=0,tD=0,tR=0;
    List<Map<String,String>> allReserves=new ArrayList<>();
    try{
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn=DriverManager.getConnection(DBURL,"root","1234");
        // 시간이 지난 예약을 자동으로 "사용완료"로 변경
        String updateSql="UPDATE reservations SET status='사용완료' WHERE status='예약완료' AND CONCAT(reserve_date,' ',end_time) < NOW()";
        conn.createStatement().executeUpdate(updateSql);
        ResultSet rs;
        rs=conn.createStatement().executeQuery("SELECT COUNT(*) FROM assets");if(rs.next())tA=rs.getInt(1);rs.close();
        rs=conn.createStatement().executeQuery("SELECT COUNT(*) FROM asset_transfer");if(rs.next())tT=rs.getInt(1);rs.close();
        rs=conn.createStatement().executeQuery("SELECT COUNT(*) FROM asset_disposal");if(rs.next())tD=rs.getInt(1);rs.close();
        rs=conn.createStatement().executeQuery("SELECT COUNT(*) FROM reservations");if(rs.next())tR=rs.getInt(1);rs.close();
        // 전체 예약 조회
        rs=conn.createStatement().executeQuery(
            "SELECT r.reserve_id,r.user_id,IFNULL(u.user_name,r.user_id) AS uname,"+
            "IFNULL(a.item_name,'강의실') AS item_name,r.reserve_date,r.start_time,r.end_time,r.status "+
            "FROM reservations r LEFT JOIN assets a ON r.asset_no=a.asset_no "+
            "LEFT JOIN users u ON r.user_id=u.user_id "+
            "ORDER BY r.reserve_date DESC,r.start_time DESC LIMIT 30");
        while(rs.next()){
            Map<String,String> m=new LinkedHashMap<>();
            m.put("id",rs.getString("reserve_id")!=null?rs.getString("reserve_id"):"");
            m.put("uid",rs.getString("user_id")!=null?rs.getString("user_id"):"");
            m.put("uname",rs.getString("uname")!=null?rs.getString("uname"):"");
            m.put("name",rs.getString("item_name")!=null?rs.getString("item_name"):"");
            m.put("date",rs.getString("reserve_date")!=null?rs.getString("reserve_date"):"");
            m.put("start",rs.getString("start_time")!=null?rs.getString("start_time"):"");
            m.put("end",rs.getString("end_time")!=null?rs.getString("end_time"):"");
            m.put("status",rs.getString("status")!=null?rs.getString("status"):"");
            allReserves.add(m);
        }
        rs.close();conn.close();
    }catch(Exception e){errMsg+="|조회오류:"+e.getMessage();}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ICT CAN — 관리자</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,700;9..40,800&family=DM+Mono:wght@400;500&family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/CAN/css/common.css">
</head>
<body>
<div class="topnav">
  <a href="/CAN/main_admin.jsp" class="logo">
    <span class="logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>
    ICT <em>CAN</em>
  </a>
  <div class="nav-right">
    <span style="font-family:var(--mono);font-size:13px;color:var(--txt2)"><i class="bi bi-person-circle"></i> <%= loginName %></span>
    <span class="role-chip">운영관리자</span>
    <a href="/CAN/search.jsp" class="chip"><i class="bi bi-search"></i> 검색</a>
    <a href="/CAN/transfer.jsp" class="chip"><i class="bi bi-arrow-left-right"></i> 이관내역</a>
    <a href="/CAN/navigationTest1.jsp" class="chip"><i class="bi bi-map"></i> 캠퍼스 지도</a>
    <a href="/CAN/asset_manage.jsp" class="chip chip-blue"><i class="bi bi-pencil-square"></i> 자원관리</a>
    <form action="/CAN/logout" method="post" style="margin:0">
      <button type="submit" class="chip"><i class="bi bi-box-arrow-right"></i> 로그아웃</button>
    </form>
  </div>
  <button class="nav-hamburger" onclick="toggleMenu()"><i class="bi bi-list"></i></button>
</div>
<div class="nav-mobile-menu" id="mobileMenu">
  <div class="nav-user-info"><i class="bi bi-person-circle me-1"></i><%= loginName %> · <span class="role-chip" style="font-size:11px">관리자</span></div>
  <a href="/CAN/search.jsp" class="chip"><i class="bi bi-search me-1"></i>검색</a>
  <a href="/CAN/transfer.jsp" class="chip"><i class="bi bi-arrow-left-right me-1"></i>이관내역</a>
  <a href="/CAN/navigationTest1.jsp" class="chip"><i class="bi bi-map me-1"></i>캠퍼스 지도</a>
  <a href="/CAN/asset_manage.jsp" class="chip chip-blue"><i class="bi bi-pencil-square me-1"></i>자원관리</a>
  <form action="/CAN/logout" method="post" style="margin:0">
    <button type="submit" class="chip" style="width:100%;justify-content:center"><i class="bi bi-box-arrow-right me-1"></i>로그아웃</button>
  </form>
</div>

<div class="shell">

<div class="hero">
  <div class="hero-content">
    <div class="hero-eyebrow">// ICT CAN · 운영관리자</div>
    <div class="hero-title">대학 자원 <em>운영 현황</em> 📊</div>
    <div class="hero-desc">DB 실시간 연동 — 전체 자산, 이관, 폐기, 예약을 통합 관리합니다.</div>
    <div class="tag-row">
      <span class="tag"><b><%= String.format("%,d",tA) %></b> 전체자산</span>
      <span class="tag"><b><%= String.format("%,d",tT) %></b> 이관</span>
      <span class="tag"><b><%= String.format("%,d",tD) %></b> 폐기</span>
      <span class="tag"><b><%= String.format("%,d",tR) %></b> 예약</span>
    </div>
  </div>
  <div class="hero-side">🛡</div>
</div>

<% if(!okMsg.isEmpty()){%><div class="alert-ok"><i class="bi bi-check-circle-fill"></i><%= okMsg %></div><%}%>
<% if(!errMsg.isEmpty()){%><div class="alert-err"><i class="bi bi-exclamation-circle-fill"></i><%= errMsg %></div><%}%>

<!-- STAT ROW -->
<div class="stat-row">
  <div class="stat-card" onclick="location.href='/CAN/search.jsp'">
    <div class="stat-icon si-blue"><i class="bi bi-box-seam" style="color:var(--blue);font-size:20px"></i></div>
    <div><div class="stat-label">전체 자산</div><div class="stat-val sv-blue"><%= String.format("%,d",tA) %></div><div class="stat-sub">DB</div></div>
  </div>
  <div class="stat-card" onclick="location.href='/CAN/transfer.jsp'">
    <div class="stat-icon si-teal"><i class="bi bi-arrow-left-right" style="color:var(--teal);font-size:20px"></i></div>
    <div><div class="stat-label">이관 이력</div><div class="stat-val sv-teal"><%= String.format("%,d",tT) %></div><div class="stat-sub">누적</div></div>
  </div>
  <div class="stat-card" onclick="location.href='/CAN/disposal_admin.jsp'" style="cursor:pointer;">
    <div class="stat-icon si-purple"><i class="bi bi-trash" style="color:var(--purple);font-size:20px"></i></div>
    <div><div class="stat-label">폐기 처리</div><div class="stat-val sv-purple"><%= String.format("%,d",tD) %></div><div class="stat-sub">누적</div></div>
  </div>
  <div class="stat-card" onclick="location.href='/CAN/reservations_admin.jsp'" style="cursor:pointer;">
    <div class="stat-icon si-amber"><i class="bi bi-calendar-check" style="color:var(--amber);font-size:20px"></i></div>
    <div><div class="stat-label">전체 예약</div><div class="stat-val sv-amber"><%= String.format("%,d",tR) %></div><div class="stat-sub">누적</div></div>
  </div>
</div>

<div class="row g-4">
  <div class="col-xl-7">

    <!-- 전체 예약 관리 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-amber"><i class="bi bi-calendar-check" style="color:var(--amber)"></i></div>
        <div><div class="ch-title">전체 예약 관리</div><div class="ch-sub">모든 예약 조회 · 최근 30건 · 선택하여 취소 가능</div></div>
      </div>
      <% if(allReserves.isEmpty()){%>
      <div class="card-body" style="text-align:center;padding:40px;color:var(--txt3)">예약 내역이 없습니다.</div>
      <%}else{%>
      <div style="overflow-x:auto">
        <table class="tbl">
          <thead>
            <tr><th>#</th><th>신청자</th><th>자산명</th><th>날짜</th><th>시간</th><th>상태</th><th>관리자취소</th></tr>
          </thead>
          <tbody>
          <%for(Map<String,String> rv:allReserves){
              String st=rv.get("status");
              String bc=st.contains("취소")?"badge-busy":st.contains("완료")?"badge-ok":"badge-warn";
          %>
          <tr>
            <td style="font-family:var(--mono);font-size:12px;color:var(--txt3)"><%= rv.get("id") %></td>
            <td><strong style="font-size:13px"><%= rv.get("uname") %></strong>
                <div style="font-size:11px;color:var(--txt3);font-family:var(--mono)"><%= rv.get("uid") %></div></td>
            <td style="font-size:13px"><%= rv.get("name") %></td>
            <td style="font-family:var(--mono);font-size:12px"><%= rv.get("date") %></td>
            <td style="font-family:var(--mono);font-size:12px"><%= rv.get("start") %>~<%= rv.get("end") %></td>
            <td><span class="<%= bc %>"><%= st %></span></td>
            <td style="display:flex;gap:6px;flex-wrap:wrap;">
              <%if("사용완료".equals(st)){%>
              <form method="post" action="/CAN/main_admin.jsp" accept-charset="UTF-8" style="margin:0;display:contents" onchange="if(confirm('[관리자] 예약 #<%= rv.get("id") %>을(를) '+this.querySelector('select').value+' 연장하시겠습니까?')) this.submit(); else this.reset()">
                <input type="hidden" name="act" value="extendReserve">
                <input type="hidden" name="reserveId" value="<%= rv.get("id") %>">
                <select name="extendHours" style="padding:4px 8px;font-size:12px;border:1.5px solid var(--line2);border-radius:6px;outline:none;background:var(--white);color:var(--txt);cursor:pointer;">
                  <option value="">연장</option>
                  <option value="1">1시간 연장</option>
                  <option value="2">2시간 연장</option>
                  <option value="4">4시간 연장</option>
                  <option value="8">8시간 연장</option>
                </select>
              </form>
              <%}else if("예약완료".equals(st)){%>
              <form method="post" action="/CAN/main_admin.jsp" accept-charset="UTF-8" style="margin:0"
                    onsubmit="return confirm('[관리자] 예약 #<%= rv.get("id") %>을 취소하시겠습니까?')">
                <input type="hidden" name="act" value="cancelReserve">
                <input type="hidden" name="reserveId" value="<%= rv.get("id") %>">
                <button type="submit" class="btn-danger" style="padding:4px 8px;font-size:12px"><i class="bi bi-x-circle"></i>취소</button>
              </form>
              <%}else{%><span style="font-size:12px;color:var(--txt3)">-</span><%}%>
            </td>
          </tr>
          <%}%>
          </tbody>
        </table>
      </div>
      <%}%>
    </div>

    <!-- 이관내역 등록 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-teal"><i class="bi bi-arrow-left-right" style="color:var(--teal)"></i></div>
        <div><div class="ch-title">이관내역 등록</div><div class="ch-sub">DB에 직접 저장됩니다</div></div>
      </div>
      <div class="card-body">
        <form method="post" action="/CAN/main_admin.jsp">
          <input type="hidden" name="act" value="addTransfer">
          <div class="row g-3">
            <div class="col-md-4">
              <label class="f-label">자산번호 *</label>
              <input class="f-input" type="text" name="t_asset_no" placeholder="예) 8402C0001" required>
            </div>
            <div class="col-md-4">
              <label class="f-label">이관일자 *</label>
              <input class="f-input" type="date" name="t_date" required>
            </div>
            <div class="col-md-4">
              <label class="f-label">이관 전 부서</label>
              <input class="f-input" type="text" name="t_from_dept" placeholder="예) AI소프트웨어학과">
            </div>
            <div class="col-md-4">
              <label class="f-label">이관 전 위치</label>
              <input class="f-input" type="text" name="t_from_loc" placeholder="예) 301호">
            </div>
            <div class="col-md-4">
              <label class="f-label">이관 후 부서</label>
              <input class="f-input" type="text" name="t_to_dept" placeholder="예) 컴퓨터공학과">
            </div>
            <div class="col-md-4">
              <label class="f-label">이관 후 위치</label>
              <input class="f-input" type="text" name="t_to_loc" placeholder="예) 402호">
            </div>
            <div class="col-12">
              <label class="f-label">비고</label>
              <input class="f-input" type="text" name="t_remark" placeholder="이관 사유 등">
            </div>
            <div class="col-12">
              <button type="submit" class="btn-success"><i class="bi bi-check-circle me-1"></i>DB에 이관내역 등록</button>
              <a href="/CAN/transfer.jsp" class="btn-ghost ms-2">전체 이관내역 보기</a>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>

  <div class="col-xl-5">
    <!-- 빠른이동 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-blue"><i class="bi bi-lightning" style="color:var(--blue)"></i></div>
        <div><div class="ch-title">빠른 이동</div></div>
      </div>
      <div class="card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
          <a href="/CAN/search.jsp" style="display:block;text-align:center;background:var(--blue-lt);border:1.5px solid var(--blue-md);border-radius:var(--r);padding:16px;text-decoration:none;color:var(--blue);font-weight:700;font-size:14px"><i class="bi bi-search d-block mb-1" style="font-size:20px"></i>자원 검색</a>
          <a href="/CAN/asset_manage.jsp" style="display:block;text-align:center;background:var(--teal-lt);border:1.5px solid var(--teal-md);border-radius:var(--r);padding:16px;text-decoration:none;color:var(--teal);font-weight:700;font-size:14px"><i class="bi bi-pencil-square d-block mb-1" style="font-size:20px"></i>자원 관리</a>
          <a href="/CAN/transfer.jsp" style="display:block;text-align:center;background:var(--purple-lt);border:1.5px solid #c4b5fd;border-radius:var(--r);padding:16px;text-decoration:none;color:var(--purple);font-weight:700;font-size:14px"><i class="bi bi-arrow-left-right d-block mb-1" style="font-size:20px"></i>이관내역</a>
          <a href="/CAN/professor.jsp" style="display:block;text-align:center;background:var(--amber-lt);border:1.5px solid #fde68a;border-radius:var(--r);padding:16px;text-decoration:none;color:var(--amber);font-weight:700;font-size:14px"><i class="bi bi-people d-block mb-1" style="font-size:20px"></i>교수 자원</a>
        </div>
      </div>
    </div>
    <!-- 운영 현황 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-amber"><i class="bi bi-clipboard-data" style="color:var(--amber)"></i></div>
        <div><div class="ch-title">운영 현황</div></div>
      </div>
      <div class="card-body" style="padding:12px 22px">
        <ul style="list-style:none;padding:0;margin:0">
          <li style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--line);font-size:14px"><span style="color:var(--txt2)">전체 자산</span><span style="font-weight:700;font-family:var(--mono);color:var(--blue)"><%= String.format("%,d",tA) %>건</span></li>
          <li style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--line);font-size:14px"><span style="color:var(--txt2)">이관 이력</span><span style="font-weight:700;font-family:var(--mono)"><%= String.format("%,d",tT) %>건</span></li>
          <li style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--line);font-size:14px"><span style="color:var(--txt2)">폐기 처리</span><span style="font-weight:700;font-family:var(--mono)"><%= String.format("%,d",tD) %>건</span></li>
          <li style="display:flex;justify-content:space-between;padding:10px 0;font-size:14px"><span style="color:var(--txt2)">전체 예약</span><span style="font-weight:700;font-family:var(--mono);color:var(--amber)"><%= String.format("%,d",tR) %>건</span></li>
        </ul>
      </div>
    </div>
  </div>
</div>

</div>
<footer class="site-footer">
  <div class="footer-inner">
    <a href="/CAN/campuslogin.jsp" class="footer-logo"><span class="footer-logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>ICT <em>CAN</em></a>
    <div class="footer-team"><strong>Made by AI 소프트웨어학과</strong><br>박승순 &middot; 권동해 &middot; 원태연 &middot; 이수혁</div>
    <div class="footer-copy">ICT폴리텍대학 교내 자원 내비게이션 시스템<br>Copyright &copy; 2026 ICT CAN. All rights reserved.</div>
  </div>
</footer>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function toggleMenu(){document.getElementById('mobileMenu').classList.toggle('open');}
</script>
</body>
</html>
