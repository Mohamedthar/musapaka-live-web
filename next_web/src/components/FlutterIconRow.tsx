import React from 'react';

export function FlutterIconRow({
  label,
  value,
  icon,
  valueColor = '#003527',
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  valueColor?: string;
}) {
  return (
    <div style={{ display: 'flex', alignItems: 'center' }}>
      <div style={{
        minWidth: '30pt', height: '30pt',
        borderRadius: '8pt',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: '#003527',
      }}>
        {icon}
      </div>
      <div style={{ marginRight: '8pt' }}>
        <p style={{
          fontSize: '9pt', fontWeight: 600,
          color: '#64748B',
          margin: 0, fontFamily: '"Cairo", sans-serif',
        }}>
          {label}
        </p>
        <p style={{
          fontSize: '11pt', fontWeight: 700,
          color: valueColor,
          margin: '2pt 0 0 0', fontFamily: '"Cairo", sans-serif',
        }}>
          {value}
        </p>
      </div>
    </div>
  );
}

export function FlutterGridCell({
  label,
  value,
  icon,
  isTopRow = false,
  bg = 'white',
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  isTopRow?: boolean;
  bg?: string;
}) {
  return (
    <div style={{
      padding: '8pt 10pt',
      display: 'flex', alignItems: 'center',
      gap: '8pt',
      background: bg,
      borderTop: isTopRow ? 'none' : '1pt solid #f1f5f9',
    }}>
      <div style={{
        minWidth: '24pt', height: '24pt',
        borderRadius: '6pt',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: '#003527',
      }}>
        {icon}
      </div>
      <div>
        <p style={{
          fontSize: '8pt', fontWeight: 600,
          color: '#94a3b8',
          margin: 0, fontFamily: '"Cairo", sans-serif',
        }}>
          {label}
        </p>
        <p style={{
          fontSize: '10pt', fontWeight: 700,
          color: '#003527',
          margin: '1pt 0 0 0', fontFamily: '"Cairo", sans-serif',
        }}>
          {value || '-'}
        </p>
      </div>
    </div>
  );
}
