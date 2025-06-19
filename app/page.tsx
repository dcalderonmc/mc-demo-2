import sql from '@/lib/db';
import { create } from './actions';

export default async function Page() {
  if (!sql) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <h1 style={{ color: '#d9534f' }}>Database connection failed</h1>
        <p style={{ color: '#666' }}>
          Please check your database configuration.
        </p>
      </div>
    );
  }
  const comments = await sql`SELECT comment FROM comments;`;

  return (
    <div
      style={{
        maxWidth: 480,
        margin: '2rem auto',
        padding: '2rem',
        background: '#fff',
        borderRadius: 12,
        boxShadow: '0 2px 8px rgba(0,0,0,0.07)'
      }}
    >
      <h1 style={{ fontSize: '2rem', marginBottom: 8, color: '#222' }}>
        Comments
      </h1>
      <p style={{ color: '#666', marginBottom: 24 }}>
        Share your thoughts below. All comments are public.
      </p>
      <ul style={{ listStyle: 'none', padding: 0, margin: '1rem 0 2rem 0' }}>
        {comments.length === 0 ? (
          <li style={{ color: '#aaa', textAlign: 'center', padding: '1rem' }}>
            No comments yet. Be the first!
          </li>
        ) : (
          comments.map((row, idx: number) => (
            <li
              key={idx}
              style={{
                background: '#f3f4f6',
                borderRadius: '8px',
                padding: '0.75rem 1rem',
                marginBottom: '0.5rem',
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
                color: '#222', // Make comment text dark
                fontSize: '1rem',
                wordBreak: 'break-word',
                fontWeight: 500
              }}
            >
              {row.comment}
            </li>
          ))
        )}
      </ul>
      <form
        action={create}
        style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 8 }}
      >
        <label htmlFor="comment" style={{ display: 'none' }}>
          Comment
        </label>
        <input
          id="comment"
          type="text"
          placeholder="Write a comment..."
          name="comment"
          required
          style={{
            flex: 1,
            padding: '0.5rem 1rem',
            border: '1px solid #ccc',
            borderRadius: 6,
            fontSize: '1rem',
            outline: 'none',
            transition: 'border 0.2s'
          }}
        />
        <button
          type="submit"
          style={{
            background: '#2563eb',
            color: '#fff',
            border: 'none',
            borderRadius: 6,
            padding: '0.5rem 1.25rem',
            fontWeight: 600,
            fontSize: '1rem',
            cursor: 'pointer',
            transition: 'background 0.2s'
          }}
        >
          Submit
        </button>
      </form>
    </div>
  );
}
