import { render, screen } from '@testing-library/react'
import App from './App.jsx'

describe('App', () => {
  it('hiển thị đủ bốn bước của pipeline', () => {
    render(<App />)

    for (const title of ['Push', 'Trigger', 'Build & Test', 'Deploy']) {
      expect(screen.getByRole('heading', { name: title })).toBeInTheDocument()
    }
  })

  it('hiển thị trạng thái triển khai thành công', () => {
    render(<App />)

    expect(screen.getByText(/deployment successful/i)).toBeInTheDocument()
    expect(screen.getByText(/Jenkins checkout đúng nhánh main/i)).toBeInTheDocument()
  })
})
