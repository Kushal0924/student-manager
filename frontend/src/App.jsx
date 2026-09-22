import { useEffect, useState } from 'react'

const API = '/api/students'

const emptyForm = { name: '', email: '', course: '', age: '' }

export default function App() {
  const [students, setStudents] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [search, setSearch] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  async function load() {
    setLoading(true)
    setError('')
    try {
      const res = await fetch(API)
      if (!res.ok) throw new Error(`GET ${res.status} — is backend running?`)
      setStudents(await res.json())
    } catch (e) {
      setError(e.message + ` (API: ${API})`)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  function onChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  async function onSubmit(e) {
    e.preventDefault()
    setError('')
    const payload = { ...form, age: form.age === '' ? null : Number(form.age) }
    try {
      const res = await fetch(editingId ? `${API}/${editingId}` : API, {
        method: editingId ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })
      if (!res.ok) {
        const txt = await res.text()
        throw new Error(txt || `Save failed (${res.status})`)
      }
      setForm(emptyForm)
      setEditingId(null)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  function onEdit(s) {
    setEditingId(s.id)
    setForm({ name: s.name, email: s.email, course: s.course, age: s.age ?? '' })
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function onDelete(id) {
    if (!confirm('Delete this student?')) return
    try {
      const res = await fetch(`${API}/${id}`, { method: 'DELETE' })
      if (!res.ok && res.status !== 204) throw new Error(`Delete failed (${res.status})`)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const filtered = students.filter(s =>
    [s.name, s.email, s.course].join(' ').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="wrap">
      <header>
        <div>
          <h1><span>▓</span> STUDENT MANAGER</h1>
        </div>
        <div className="badge">{students.length} students</div>
      </header>

      {error && <div className="error">{error}</div>}

      <div className="card">
        <form onSubmit={onSubmit}>
          <div className="row">
            <div><label>Name</label><input name="name" value={form.name} onChange={onChange} required placeholder="Ada Lovelace" /></div>
            <div><label>Email</label><input name="email" type="email" value={form.email} onChange={onChange} required placeholder="ada@school.edu" /></div>
          </div>
          <div className="row" style={{ marginTop: 12 }}>
            <div><label>Course</label><input name="course" value={form.course} onChange={onChange} required placeholder="Computer Science" /></div>
            <div><label>Age</label><input name="age" type="number" min="1" max="120" value={form.age} onChange={onChange} placeholder="20" /></div>
          </div>
          <div className="actions">
            <button className="btn-add" type="submit">{editingId ? 'Update student' : '+ Add student'}</button>
            {editingId && <button className="btn-cancel" type="button" onClick={() => { setEditingId(null); setForm(emptyForm) }}>Cancel</button>}
          </div>
        </form>
      </div>

      <div className="toolbar">
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search name / email / course…" />
        <button className="btn-cancel" onClick={load}>↻ Refresh</button>
      </div>

      <div className="card">
        {loading ? <div className="empty">loading…</div> :
          filtered.length === 0 ? <div className="empty">no students yet — add one above</div> : (
          <table>
            <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Course</th><th>Age</th><th></th></tr></thead>
            <tbody>
              {filtered.map(s => (
                <tr key={s.id}>
                  <td className="id-pill">#{s.id}</td>
                  <td>{s.name}</td>
                  <td>{s.email}</td>
                  <td><span className="course-pill">{s.course}</span></td>
                  <td>{s.age ?? '—'}</td>
                  <td style={{ whiteSpace: 'nowrap' }}>
                    <button className="btn-edit" onClick={() => onEdit(s)}>Edit</button>{' '}
                    <button className="btn-del" onClick={() => onDelete(s.id)}>Del</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="footer">backend :8080 · db: mariadb studentdb · frontend :5173 · local only</div>
    </div>
  )
}
