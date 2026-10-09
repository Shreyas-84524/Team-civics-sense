/**
 * CivicFix Public Verification Client Application
 */

document.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URLSearchParams(window.location.search);
  let slug = urlParams.get('slug');

  // If path was /verify/v_12345
  if (!slug) {
    const segments = window.location.pathname.split('/');
    if (segments.length >= 3 && segments[1] === 'verify') {
      slug = segments[2];
    }
  }

  const appRoot = document.getElementById('app-root');

  if (!slug) {
    renderInvalid(appRoot, 'No verification reference provided.');
    return;
  }

  fetch(`/api/verify?slug=${encodeURIComponent(slug)}`)
    .then(res => res.json())
    .then(data => {
      if (data.state === 'valid') {
        renderValid(appRoot, data.certificate);
      } else if (data.state === 'revoked') {
        renderRevoked(appRoot, data.certificate, data.message);
      } else {
        renderInvalid(appRoot, data.message);
      }
    })
    .catch(err => {
      renderInvalid(appRoot, 'Unable to complete verification at this time. Please try again later.');
    });
});

function formatDate(isoStr) {
  try {
    const d = new Date(isoStr);
    return d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  } catch (e) {
    return isoStr;
  }
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function renderValid(container, cert) {
  container.innerHTML = `
    <div class="trust-banner valid">
      <div style="display: flex; align-items: center; gap: 0.75rem;">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
          <path d="m9 12 2 2 4-4"></path>
        </svg>
        <div>
          <div style="font-weight: 700; font-size: 0.95rem;">Certificate Verified</div>
          <div style="font-size: 0.8rem; opacity: 0.9;">Authentic CivicFix Achievement Record</div>
        </div>
      </div>
      <span class="status-badge valid">VALID</span>
    </div>

    <div class="card">
      <div class="cert-header">
        <div class="cert-icon-wrapper">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="8" r="7"></circle>
            <polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"></polyline>
          </svg>
        </div>
        <div>
          <div class="cert-title">${escapeHtml(cert.certificateTitle)}</div>
          <div class="recipient-name">Awarded to ${escapeHtml(cert.recipientDisplayName)}</div>
        </div>
      </div>

      <div class="divider"></div>

      <div class="info-grid">
        <div class="info-label">Recipient</div>
        <div class="info-value">${escapeHtml(cert.recipientDisplayName)}</div>

        <div class="info-label">Civic Level / Tier</div>
        <div class="info-value">${escapeHtml(cert.civicLevel)}</div>

        <div class="info-label">Certificate ID</div>
        <div class="info-value" style="font-family: monospace;">${escapeHtml(cert.certificateId)}</div>

        <div class="info-label">Date of Issue</div>
        <div class="info-value">${formatDate(cert.issuedAt)}</div>

        <div class="info-label">Status</div>
        <div class="info-value" style="color: #059669; font-weight: 700;">VALID / ACTIVE</div>
      </div>

      <div style="font-size: 0.875rem; font-weight: 700; color: var(--text-primary);">Verified Civic Impact at Issue</div>
      <div class="metrics-row">
        <div class="metric-card">
          <div class="metric-value">+${cert.pointsAtIssue}</div>
          <div class="metric-label">Civic Points</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">${cert.verifiedComplaintsAtIssue}</div>
          <div class="metric-label">Verified Reports</div>
        </div>
        <div class="metric-card">
          <div class="metric-value">${cert.resolvedComplaintsAtIssue}</div>
          <div class="metric-label">Resolved Reports</div>
        </div>
      </div>

      <div style="font-size: 0.875rem; font-weight: 700; color: var(--text-primary); margin-top: 1rem;">Why this certificate was awarded</div>
      <div class="award-reason-box">
        <h4>${escapeHtml(cert.achievementReason)}</h4>
        <p>${escapeHtml(cert.awardImportance)}</p>
      </div>
    </div>
  `;
}

function renderRevoked(container, cert, message) {
  container.innerHTML = `
    <div class="trust-banner revoked">
      <div style="display: flex; align-items: center; gap: 0.75rem;">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#DC2626" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="15" y1="9" x2="9" y2="15"></line>
          <line x1="9" y1="9" x2="15" y2="15"></line>
        </svg>
        <div>
          <div style="font-weight: 800; font-size: 0.95rem; letter-spacing: 0.03em;">CERTIFICATE REVOKED</div>
          <div style="font-size: 0.8rem; opacity: 0.9;">This certificate is no longer considered valid by CivicFix.</div>
        </div>
      </div>
      <span class="status-badge revoked">REVOKED</span>
    </div>

    ${cert ? `
    <div class="card">
      <h3 style="font-size: 1.05rem; font-weight: 700; margin-bottom: 0.5rem;">Historical Record Reference</h3>
      <p style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 1.25rem;">
        The following achievement record was previously issued but has been formally invalidated:
      </p>

      <div class="info-grid">
        <div class="info-label">Recipient</div>
        <div class="info-value">${escapeHtml(cert.recipientDisplayName)}</div>

        <div class="info-label">Original Title</div>
        <div class="info-value">${escapeHtml(cert.certificateTitle)}</div>

        <div class="info-label">Certificate ID</div>
        <div class="info-value" style="font-family: monospace;">${escapeHtml(cert.certificateId)}</div>

        <div class="info-label">Date of Original Issue</div>
        <div class="info-value">${formatDate(cert.issuedAt)}</div>

        ${cert.revocationReason ? `
        <div class="info-label">Revocation Reason</div>
        <div class="info-value" style="color: #DC2626;">${escapeHtml(cert.revocationReason)}</div>
        ` : ''}

        <div class="info-label">Current Status</div>
        <div class="info-value" style="color: #DC2626; font-weight: 800;">REVOKED (INVALID)</div>
      </div>
    </div>
    ` : ''}
  `;
}

function renderInvalid(container, message) {
  container.innerHTML = `
    <div class="card invalid-container">
      <div style="width: 56px; height: 56px; border-radius: 50%; background: #FEF3C7; color: #D97706; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.25rem;">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
          <line x1="12" y1="9" x2="12" y2="13"></line>
          <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>
      </div>

      <h2 style="font-size: 1.3rem; font-weight: 800; margin-bottom: 0.5rem;">Certificate Not Verified</h2>
      <p style="font-size: 0.9rem; color: var(--text-secondary); max-width: 440px; margin: 0 auto 1.5rem;">
        ${escapeHtml(message || 'No valid CivicFix certificate was found for this verification reference.')}
      </p>

      <div style="background: var(--surface-muted); border: 1px solid var(--border); border-radius: var(--radius-md); padding: 0.85rem; font-size: 0.8rem; color: var(--text-secondary); max-width: 440px; margin: 0 auto;">
        Please ensure the QR code was scanned directly from an authentic CivicFix achievement certificate.
      </div>
    </div>
  `;
}
