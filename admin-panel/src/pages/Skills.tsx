import React, { useState } from 'react';
import { Skill } from '../types';

interface SkillsProps {
  skills: Skill[];
  onAddSkill: (name: string) => Promise<void>;
  onEditSkill: (id: number, name: string) => Promise<void>;
  onDeleteSkill: (id: number) => Promise<void>;
}

export default function Skills({ skills, onAddSkill, onEditSkill, onDeleteSkill }: SkillsProps) {
  const [newSkillName, setNewSkillName] = useState('');
  const [editingSkillId, setEditingSkillId] = useState<number | null>(null);
  const [editingSkillName, setEditingSkillName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSkillName.trim()) return;
    await onAddSkill(newSkillName.trim());
    setNewSkillName('');
  };

  const handleStartEdit = (skill: Skill) => {
    setEditingSkillId(skill.id);
    setEditingSkillName(skill.name);
  };

  const handleSave = async (id: number) => {
    if (!editingSkillName.trim()) return;
    await onEditSkill(id, editingSkillName.trim());
    setEditingSkillId(null);
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 2fr', gap: '24px', alignItems: 'start' }}>
      {/* Create Skill Form */}
      <div className="glass-card">
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '18px' }}>افزودن تخصص جوشکاری جدید</h3>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="skillName">عنوان تخصص (فارسی)</label>
            <input 
              type="text" 
              id="skillName"
              className="input-control"
              placeholder="مثال: جوشکاری آرگون تحت فشار"
              value={newSkillName}
              onChange={(e) => setNewSkillName(e.target.value)}
              required
            />
          </div>
          <button type="submit" className="btn btn-primary" style={{ width: '100%', height: '42px' }}>
            ثبت تخصص جدید
          </button>
        </form>
      </div>

      {/* Skills Table List */}
      <div className="glass-card">
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>لیست کل تخصص‌های مجاز پلتفرم</h3>
        
        {skills.length === 0 ? (
          <div style={{ padding: '30px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>هیچ تخصصی در سیستم ثبت نشده است.</div>
        ) : (
          <div className="table-responsive">
            <table className="custom-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>شناسه</th>
                  <th>عنوان تخصص</th>
                  <th style={{ width: '160px', textAlign: 'left' }}>عملیات مدیریتی</th>
                </tr>
              </thead>
              <tbody>
                {skills.map((skill) => (
                  <tr key={skill.id}>
                    <td>#{skill.id}</td>
                    <td>
                      {editingSkillId === skill.id ? (
                        <input 
                          type="text" 
                          className="input-control" 
                          style={{ padding: '4px 8px', fontSize: '13px' }}
                          value={editingSkillName}
                          onChange={(e) => setEditingSkillName(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') handleSave(skill.id);
                            else if (e.key === 'Escape') setEditingSkillId(null);
                          }}
                        />
                      ) : (
                        <span style={{ fontWeight: '500' }}>{skill.name}</span>
                      )}
                    </td>
                    <td style={{ textAlign: 'left' }}>
                      {editingSkillId === skill.id ? (
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                          <button 
                            className="btn btn-success" 
                            style={{ padding: '4px 10px', fontSize: '11px' }}
                            onClick={() => handleSave(skill.id)}
                          >
                            ذخیره
                          </button>
                          <button 
                            className="btn btn-secondary" 
                            style={{ padding: '4px 10px', fontSize: '11px' }}
                            onClick={() => setEditingSkillId(null)}
                          >
                            انصراف
                          </button>
                        </div>
                      ) : (
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                          <button 
                            className="btn btn-secondary" 
                            style={{ padding: '4px 10px', fontSize: '11px' }}
                            onClick={() => handleStartEdit(skill)}
                          >
                            ویرایش
                          </button>
                          <button 
                            className="btn btn-danger" 
                            style={{ padding: '4px 10px', fontSize: '11px' }}
                            onClick={() => onDeleteSkill(skill.id)}
                          >
                            حذف
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
