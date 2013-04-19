module json2colorer;

import std.array;
import std.file;
import std.string;
import std.stdio;

import ae.utils.json;
import ae.utils.text;
import ae.utils.xml;

struct DSymbol
{
	string name;
	string kind;
	string file;
	int line;
	int endline;
	string type;
	string deco, baseDeco, defaultDeco;
	string originalType;
	string comment;
	DSymbol[] members;
	DSymbol[] parameters;
	string protection;
	string base;
	string[] storageClass;
	string[] interfaces;
	string[] overrides;
	@JSONName("alias") string alias_;
	string defaultAlias;
	string[] selective;
	string[string] renamed;
	@JSONName("in" ) DSymbol* in_ ;
	@JSONName("out") DSymbol* out_;
	@JSONName("default") string default_;
	string defaultValue, specValue, init;
	int offset;
	@JSONName("align") int align_;
}

void main(string[] args)
{
	string[][string][string] results;
	foreach (de; dirEntries(args[1], "*.json", SpanMode.shallow))
	{
		auto modules = jsonParse!(DSymbol[])(readText(de.name));
		foreach (mod; modules)
		{
			if (mod.file.startsWith("internal")) continue;
			if (mod.name.startsWith("rt.")) continue;
			if (mod.name.startsWith("std.typeinfo")) continue;
			if (mod.name=="") continue; // various internal modules
			if (mod.name=="std.compiler") continue; // is meant to be static-imported


			foreach (member; mod.members)
				if (member.protection=="public" || member.protection=="export" || member.protection=="")
				{
					string name = member.name;
					if (name.startsWith("__unittest"))
						continue;
					if (name.contains("("))
						name = name[0..name.indexOf("(")];
					results[member.kind][mod.name] ~= name;
				}
		}
	}

	string[] kindSort = [
		"alias",
		"typedef",
		"template",
		"struct",
		"union",
		"class",
		"interface",
		"enum",
		"enum member",
		"variable",
		"function",
	];

	foreach (kind; kindSort)
		if (kind in results)
		{
			auto modules = results[kind];
			writefln("\t<keywords region='key.lib.%s'>", kind.replace(" ", "-"));
			foreach (moduleName; modules.keys.sort)
			{
				auto members = modules[moduleName];
				bool[string] seen;
				writefln("\t\t<!-- %s -->", moduleName);
				foreach (member; members)
				{
					if (member in seen)
						continue;
					seen[member] = true;
					writefln("\t\t<word name='%s'/>", encodeEntities(member));
				}
			}
			writefln("\t</keywords>");
			writefln("\t");
		}
}
