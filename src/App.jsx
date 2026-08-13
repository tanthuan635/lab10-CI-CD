const pipeline = [
  {
    number: '01',
    title: 'Push',
    description: 'Lập trình viên đẩy thay đổi mới lên nhánh main của GitHub.',
  },
  {
    number: '02',
    title: 'Trigger',
    description: 'GitHub webhook thông báo cho Jenkins ngay khi có commit mới.',
  },
  {
    number: '03',
    title: 'Build & Test',
    description: 'Jenkins cài thư viện, chạy kiểm thử và tạo bản build production.',
  },
  {
    number: '04',
    title: 'Deploy',
    description: 'Phiên bản cũ được sao lưu trước khi bản build mới được triển khai.',
  },
]

const checks = [
  'GitHub webhook đã gửi sự kiện push',
  'Jenkins checkout đúng nhánh main',
  'Kiểm thử và build React thành công',
  'Thư mục triển khai chứa phiên bản mới',
]

function PipelineIcon({ index }) {
  const icons = [
    <path key="push" d="M12 16V4m0 0L7 9m5-5 5 5M5 20h14" />,
    <path key="trigger" d="M13 2 4.5 13h7L11 22l8.5-12h-7L13 2Z" />,
    <path key="build" d="m14.7 6.3 3-3a4.24 4.24 0 0 1-5.1 5.1l-6.9 6.9a2.12 2.12 0 1 0 3 3l6.9-6.9a4.24 4.24 0 0 1 5.1-5.1l-3 3-3-3Z" />,
    <path key="deploy" d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16ZM3.3 7 12 12l8.7-5M12 22V12" />,
  ]

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      {icons[index]}
    </svg>
  )
}

function App() {
  const buildVersion = import.meta.env.VITE_BUILD_VERSION || 'local-dev'

  return (
    <div className="app-shell">
      <header className="topbar">
        <a className="brand" href="#top" aria-label="Về đầu trang">
          <span className="brand-mark">10</span>
          <span>
            <strong>LAB CI/CD</strong>
            <small>React · Jenkins · GitHub</small>
          </span>
        </a>
        <a className="status-pill" href="#status">
          <span className="pulse" /> Pipeline ready
        </a>
      </header>

      <main id="top">
        <section className="hero">
          <div className="hero-copy">
            <p className="eyebrow">BÀI THỰC HÀNH 10</p>
            <h1>
              Từ một <span>commit</span>
              <br />đến production.
            </h1>
            <p className="lead">
              Mô phỏng quy trình tích hợp và triển khai liên tục: GitHub gửi webhook,
              Jenkins tự động kiểm thử, build và đưa ứng dụng React lên máy chủ.
            </p>
            <div className="hero-actions">
              <a className="primary-button" href="#pipeline">Xem quy trình</a>
              <a className="text-button" href="#status">Kiểm tra trạng thái <span>→</span></a>
            </div>
          </div>

          <div className="terminal" aria-label="Kết quả mô phỏng Jenkins console">
            <div className="terminal-bar">
              <span /><span /><span />
              <p>Jenkins Console</p>
            </div>
            <div className="terminal-body">
              <p><i>$</i> git checkout main</p>
              <p className="muted">Branch is up to date with origin/main</p>
              <p><i>$</i> npm ci</p>
              <p className="success">✓ Dependencies installed</p>
              <p><i>$</i> npm test -- --run</p>
              <p className="success">✓ All tests passed</p>
              <p><i>$</i> npm run build</p>
              <p className="success">✓ Production build created</p>
              <p className="deploy-line">DEPLOYMENT SUCCESSFUL <b>●</b></p>
            </div>
          </div>
        </section>

        <section className="pipeline-section" id="pipeline">
          <div className="section-heading">
            <p className="eyebrow">AUTOMATION FLOW</p>
            <h2>Một lần push, bốn bước tự động</h2>
          </div>
          <div className="pipeline-grid">
            {pipeline.map((item, index) => (
              <article className="pipeline-card" key={item.title}>
                <div className="card-top">
                  <span className="icon-wrap"><PipelineIcon index={index} /></span>
                  <span className="step-number">{item.number}</span>
                </div>
                <h3>{item.title}</h3>
                <p>{item.description}</p>
                {index < pipeline.length - 1 && <span className="connector" aria-hidden="true">→</span>}
              </article>
            ))}
          </div>
        </section>

        <section className="status-section" id="status">
          <div>
            <p className="eyebrow">DELIVERY CHECKLIST</p>
            <h2>Sẵn sàng để trình diễn</h2>
            <p className="status-intro">
              Dùng danh sách này để đối chiếu Console Output khi giảng viên yêu cầu
              chạy trực tiếp quy trình.
            </p>
          </div>
          <div className="checklist">
            {checks.map((check) => (
              <div className="check-row" key={check}>
                <span className="check-icon">✓</span>
                <span>{check}</span>
              </div>
            ))}
            <div className="version-row">
              <span>BUILD VERSION</span>
              <code>{buildVersion}</code>
            </div>
          </div>
        </section>
      </main>

      <footer>
        <span>Software Engineering · Lab 10</span>
        <span>Continuous delivery, made visible.</span>
      </footer>
    </div>
  )
}

export default App
